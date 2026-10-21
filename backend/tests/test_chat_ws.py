import pytest
from channels.db import database_sync_to_async
from channels.routing import URLRouter
from channels.testing.websocket import WebsocketCommunicator
from django.core.cache import cache

from apps.accounts.models import AuthToken
from apps.chat import services
from apps.chat.middleware import OriginAndAuthMiddleware
from apps.chat.models import Message
from apps.chat.routing import websocket_urlpatterns

pytestmark = [pytest.mark.django_db(transaction=True), pytest.mark.asyncio]
APP = OriginAndAuthMiddleware(URLRouter(websocket_urlpatterns))


def token_for(user) -> str:
    return AuthToken.issue(user)[1]


async def connect(conv, user=None, token=None, headers=None):
    raw = token or (await database_sync_to_async(token_for)(user) if user else None)
    protocols = ["bearer", raw] if raw else []
    comm = WebsocketCommunicator(APP, f"/ws/chat/{conv.pk}/", headers=headers or [], subprotocols=protocols)
    ok, detail = await comm.connect()
    return comm, ok, detail


@pytest.fixture
def dm(owner, worker):
    return services.open_direct(owner, worker)


async def drain_snapshot(comm):
    frame = await comm.receive_json_from()
    assert frame["type"] == "presence.snapshot"


async def test_unauthenticated_rejected(dm):
    _, ok, code = await connect(dm)
    assert not ok and code == 4401
    _, ok, code = await connect(dm, token="not-a-real-token")
    assert not ok and code == 4401


async def test_non_member_and_unknown_conversation_rejected(dm, worker2):
    _, ok, code = await connect(dm, worker2)
    assert not ok and code == 4403


async def test_bad_origin_rejected(dm, owner):
    _, ok, code = await connect(dm, owner, headers=[(b"origin", b"https://evil.example")])
    assert not ok and code == 4403


async def test_allowed_origin_accepted(dm, owner, settings):
    settings.WS_ALLOWED_ORIGINS = ["https://tasks.example.com"]
    comm, ok, _ = await connect(dm, owner, headers=[(b"origin", b"https://tasks.example.com")])
    assert ok
    await comm.disconnect()


async def test_message_roundtrip_persisted_and_sender_from_connection(dm, owner, worker):
    a, ok_a, _ = await connect(dm, owner)
    b, ok_b, _ = await connect(dm, worker)
    assert ok_a and ok_b
    await drain_snapshot(a)
    # a also sees worker's presence, b gets its own snapshot
    await a.receive_json_from()
    await drain_snapshot(b)
    await a.send_json_to({"type": "message.send", "body": "hello", "client_msg_id": "c1", "sender": worker.pk})
    seen_a = {(f := await a.receive_json_from())["type"]: f for _ in range(2)}  # ack and new, in either order
    seen_b = await b.receive_json_from()
    got = [seen_a["message.new"]["message"], seen_b["message"]]
    assert all(m["body"] == "hello" and m["sender"] == owner.pk for m in got)  # spoofed "sender" ignored
    assert seen_a["message.ack"] == {"type": "message.ack", "client_msg_id": "c1", "id": got[0]["id"], "duplicate": False}
    assert await database_sync_to_async(Message.objects.count)() == 1
    await a.disconnect()
    await b.disconnect()


async def test_history_survives_reconnect_and_retry_is_idempotent(dm, owner):
    comm, _, _ = await connect(dm, owner)
    await drain_snapshot(comm)
    for _ in range(2):  # same client_msg_id twice (client retried after a reconnect)
        await comm.send_json_to({"type": "message.send", "body": "once", "client_msg_id": "dup"})
        frames = [await comm.receive_json_from() for _ in range(2 if _ == 0 else 1)]
    assert frames[-1]["duplicate"] is True
    await comm.disconnect()
    assert await database_sync_to_async(Message.objects.filter(body="once").count)() == 1
    again, ok, _ = await connect(dm, owner)
    assert ok
    await again.disconnect()


@pytest.mark.parametrize(
    "frame",
    [
        {"type": "message.send", "body": ""},
        {"type": "message.send", "body": 123},
        {"type": "message.send", "body": "x" * 4001},
        {"type": "message.send", "body": "ok", "client_msg_id": "z" * 65},
        {"type": "message.read", "message_id": "1"},
        {"type": "nope"},
    ],
)
async def test_invalid_payloads_get_generic_error(dm, owner, frame):
    comm, _, _ = await connect(dm, owner)
    await drain_snapshot(comm)
    await comm.send_json_to(frame)
    reply = await comm.receive_json_from()
    assert reply["type"] == "error" and "x" * 10 not in str(reply)
    await comm.disconnect()
    assert await database_sync_to_async(Message.objects.count)() == 0


async def test_oversized_frame_closes_connection(dm, owner):
    comm, _, _ = await connect(dm, owner)
    await drain_snapshot(comm)
    await comm.send_to(text_data="x" * 20000)
    out = await comm.receive_output()
    assert out["type"] == "websocket.close" and out["code"] == 1009


async def test_rate_limit(dm, owner, settings):
    settings.CHAT_MESSAGES_PER_MINUTE = 2
    comm, _, _ = await connect(dm, owner)
    await drain_snapshot(comm)
    replies = []
    for i in range(4):
        await comm.send_json_to({"type": "message.send", "body": f"m{i}"})
        replies.append(await comm.receive_json_from())
        while replies[-1]["type"] == "message.new":
            replies.append(await comm.receive_json_from())
    assert any(r.get("code") == "rate_limited" for r in replies)
    await comm.disconnect()


async def test_connection_limit_per_user(dm, owner, settings):
    settings.WS_MAX_CONNECTIONS_PER_USER = 1
    first, ok1, _ = await connect(dm, owner)
    _, ok2, code = await connect(dm, owner)
    assert ok1 and not ok2 and code == 4429
    await first.disconnect()
    third, ok3, _ = await connect(dm, owner)  # slot released on disconnect
    assert ok3
    await third.disconnect()


async def test_removed_member_is_disconnected_and_blocked(owner, assistant, worker):
    group = await database_sync_to_async(services.create_group)(assistant, "Crew", [worker])
    comm, ok, _ = await connect(group, worker)
    assert ok
    await drain_snapshot(comm)
    await database_sync_to_async(services.remove_member)(assistant, group, worker)
    frame = await comm.receive_json_from()
    assert frame == {"type": "revoked"}
    out = await comm.receive_output()
    assert out["type"] == "websocket.close" and out["code"] == 4403
    _, ok, code = await connect(group, worker)
    assert not ok and code == 4403


async def test_stale_socket_cannot_send_after_membership_ends(owner, assistant, worker):
    group = await database_sync_to_async(services.create_group)(assistant, "Crew", [worker])
    comm, _, _ = await connect(group, worker)
    await drain_snapshot(comm)
    # revoke in DB only (push lost, e.g. Redis outage): the per-message DB check must still stop the send
    from apps.chat.models import Membership
    from django.utils import timezone

    await database_sync_to_async(Membership.objects.filter(conversation=group, user=worker).update)(left_at=timezone.now())
    await comm.send_json_to({"type": "message.send", "body": "sneaky"})
    out = await comm.receive_output()
    assert out["type"] == "websocket.close" and out["code"] == 4403
    assert await database_sync_to_async(Message.objects.count)() == 0


async def test_task_room_requires_task_visibility(owner, worker, worker2):
    from apps.tasks import services as task_services

    def build():
        task = task_services.create_task(owner, {"title": "T", "worker_ids": [worker.pk]})
        return services.open_task_chat(owner, task.pk)

    room = await database_sync_to_async(build)()
    ok_comm, ok, _ = await connect(room, worker)
    assert ok
    await ok_comm.disconnect()
    _, ok, code = await connect(room, worker2)
    assert not ok and code == 4403


async def test_redis_failure_does_not_lose_message(dm, owner, monkeypatch):
    def boom(*a, **k):
        raise ConnectionError("redis down")

    monkeypatch.setattr(services, "get_channel_layer", boom)
    message, created = await database_sync_to_async(services.send_message)(owner, dm, "still saved", "k1")
    assert created and await database_sync_to_async(Message.objects.filter(pk=message.pk).exists)()


async def test_presence_online_offline(dm, owner, worker):
    a, _, _ = await connect(dm, owner)
    await drain_snapshot(a)
    b, _, _ = await connect(dm, worker)
    assert await a.receive_json_from() == {"type": "presence", "user": worker.pk, "online": True}
    await b.disconnect()
    assert await a.receive_json_from() == {"type": "presence", "user": worker.pk, "online": False}
    await a.disconnect()
    cache.clear()
