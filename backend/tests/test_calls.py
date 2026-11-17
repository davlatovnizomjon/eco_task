from datetime import timedelta

import pytest
from channels.db import database_sync_to_async
from channels.routing import URLRouter
from channels.testing.websocket import WebsocketCommunicator
from django.utils import timezone

from apps.accounts.models import AuthToken
from apps.chat import services
from apps.chat.middleware import OriginAndAuthMiddleware
from apps.chat.models import Call
from apps.chat.routing import websocket_urlpatterns
from apps.notifications.models import Notification
from tests.conftest import api_as

C = "/api/v1/conversations/"
CALLS = "/api/v1/calls/"


@pytest.fixture
def dm(owner, worker):
    return services.open_direct(owner, worker)


@pytest.fixture
def group(owner, assistant, worker, worker2):
    return services.create_group(owner, "Team", [assistant, worker, worker2])


def start(user, conv, kind="AUDIO"):
    return api_as(user).post(f"{C}{conv.pk}/calls/", {"kind": kind}, format="json")


@pytest.mark.django_db
class TestRest:
    def test_start_invites_the_other_member_and_lists_participants(self, owner, worker, dm):
        r = start(owner, dm, "VIDEO")
        assert r.status_code == 201 and r.data["status"] == "RINGING" and r.data["kind"] == "VIDEO"
        states = {p["user"]["id"]: p["state"] for p in r.data["participants"]}
        assert states == {owner.pk: "JOINED", worker.pk: "INVITED"}
        assert api_as(worker).get(f"{CALLS}{r.data['id']}/").status_code == 200

    def test_outsiders_and_task_chats_cannot_call(self, owner, worker, worker2, dm):
        assert start(worker2, dm).status_code == 404
        call_id = start(owner, dm).data["id"]
        assert api_as(worker2).get(f"{CALLS}{call_id}/").status_code == 404
        assert api_as(worker2).post(f"{CALLS}{call_id}/answer/").status_code == 404

    def test_only_one_live_call_per_conversation(self, owner, worker, dm):
        assert start(owner, dm).status_code == 201
        r = start(worker, dm)
        assert r.status_code == 409 and r.data["error"]["code"] == "call_in_progress"

    def test_answer_activates_and_end_closes_a_direct_call(self, owner, worker, dm):
        call_id = start(owner, dm).data["id"]
        r = api_as(worker).post(f"{CALLS}{call_id}/answer/")
        assert r.data["status"] == "ACTIVE" and r.data["answered_at"]
        r = api_as(worker).post(f"{CALLS}{call_id}/end/")
        assert r.data["status"] == "ENDED" and r.data["ended_at"]
        assert api_as(owner).post(f"{CALLS}{call_id}/answer/").status_code == 409
        assert start(owner, dm).status_code == 201  # the room is free again

    def test_decline_ends_a_direct_call_for_everyone(self, owner, worker, dm):
        call_id = start(owner, dm).data["id"]
        r = api_as(worker).post(f"{CALLS}{call_id}/decline/")
        assert r.data["status"] == "DECLINED"
        assert api_as(worker).post(f"{CALLS}{call_id}/decline/").status_code == 409

    def test_caller_cancelling_a_ringing_call_marks_it_missed_for_the_callee(self, owner, worker, dm):
        call_id = start(owner, dm).data["id"]
        r = api_as(owner).post(f"{CALLS}{call_id}/end/")
        assert r.data["status"] == "CANCELED"
        assert Notification.objects.filter(user=worker, kind="call.missed").exists()

    def test_unanswered_call_becomes_missed(self, owner, worker, dm):
        call_id = start(owner, dm).data["id"]
        Call.objects.filter(pk=call_id).update(created_at=timezone.now() - timedelta(seconds=120))
        r = api_as(worker).get(f"{CALLS}{call_id}/")
        assert r.data["status"] == "MISSED"
        assert Notification.objects.filter(user=worker, kind="call.missed").exists()
        assert start(owner, dm).status_code == 201

    def test_group_call_continues_until_everybody_left(self, owner, assistant, worker, group):
        call_id = start(owner, group, "AUDIO").data["id"]
        assert len(api_as(owner).get(f"{CALLS}{call_id}/").data["participants"]) == 4
        api_as(worker).post(f"{CALLS}{call_id}/answer/")
        api_as(assistant).post(f"{CALLS}{call_id}/decline/")
        assert api_as(owner).get(f"{CALLS}{call_id}/").data["status"] == "ACTIVE"
        api_as(owner).post(f"{CALLS}{call_id}/end/")
        assert api_as(owner).get(f"{CALLS}{call_id}/").data["status"] == "ACTIVE"  # the worker is still in it
        assert api_as(worker).post(f"{CALLS}{call_id}/end/").data["status"] == "ENDED"

    def test_group_declines_of_all_invitees_finish_the_call(self, owner, assistant, worker, worker2, group):
        call_id = start(owner, group).data["id"]
        for u in (assistant, worker):
            api_as(u).post(f"{CALLS}{call_id}/decline/")
        assert api_as(owner).get(f"{CALLS}{call_id}/").data["status"] == "RINGING"
        assert api_as(worker2).post(f"{CALLS}{call_id}/decline/").data["status"] == "DECLINED"

    def test_invite_adds_group_members_only_for_joined_participants(self, owner, worker, worker2, assistant):
        grp = services.create_group(owner, "Small", [worker])
        call_id = start(owner, grp).data["id"]
        assert (
            api_as(worker).post(f"{CALLS}{call_id}/invite/", {"user_ids": [worker2.pk]}, format="json").status_code
            == 403
        )
        services.add_members(owner, grp, [worker2])
        r = api_as(owner).post(f"{CALLS}{call_id}/invite/", {"user_ids": [worker2.pk, assistant.pk]}, format="json")
        assert {p["user"]["id"] for p in r.data["participants"]} == {
            owner.pk,
            worker.pk,
            worker2.pk,
        }  # assistant is no member

    def test_history_lists_calls_of_the_room_newest_first(self, owner, worker, dm):
        first = start(owner, dm).data["id"]
        api_as(owner).post(f"{CALLS}{first}/end/")
        second = start(worker, dm).data["id"]
        rows = api_as(owner).get(f"{C}{dm.pk}/calls/").data
        assert [c["id"] for c in rows] == [second, first]
        assert api_as(owner).get(f"{C}{dm.pk}/calls/").status_code == 200


# --- signalling ------------------------------------------------------------------------------
APP = OriginAndAuthMiddleware(URLRouter(websocket_urlpatterns))


async def connect_me(user):
    raw = await database_sync_to_async(lambda: AuthToken.issue(user)[1])()
    comm = WebsocketCommunicator(APP, "/ws/me/", subprotocols=["bearer", raw])
    ok, detail = await comm.connect()
    return comm, ok, detail


@pytest.mark.django_db(transaction=True)
@pytest.mark.asyncio
class TestSignalling:
    async def test_unauthenticated_socket_is_rejected(self, db):
        comm = WebsocketCommunicator(APP, "/ws/me/", subprotocols=[])
        ok, code = await comm.connect()
        assert not ok and code == 4401

    async def test_incoming_call_event_reaches_the_callee_and_signals_relay_between_participants(
        self, owner, worker, dm
    ):
        callee, ok, _ = await connect_me(worker)
        assert ok
        r = await database_sync_to_async(start)(owner, dm, "VIDEO")
        event = await callee.receive_json_from()
        assert event["type"] == "call.incoming" and event["call"]["id"] == r.data["id"]
        caller, ok, _ = await connect_me(owner)
        await caller.send_json_to(
            {"type": "call.signal", "call": r.data["id"], "to": worker.pk, "data": {"sdp": "offer"}}
        )
        got = await callee.receive_json_from()
        assert got == {"type": "call.signal", "call": r.data["id"], "from": owner.pk, "data": {"sdp": "offer"}}
        await callee.disconnect()
        await caller.disconnect()

    async def test_signal_to_a_non_participant_is_refused(self, owner, worker, worker2, dm):
        r = await database_sync_to_async(start)(owner, dm)
        caller, _, _ = await connect_me(owner)
        await caller.send_json_to({"type": "call.signal", "call": r.data["id"], "to": worker2.pk, "data": {}})
        assert (await caller.receive_json_from())["code"] == "forbidden"
        await caller.send_json_to({"type": "call.signal", "call": "x", "to": 1, "data": {}})
        assert (await caller.receive_json_from())["code"] == "invalid_signal"
        await caller.disconnect()
