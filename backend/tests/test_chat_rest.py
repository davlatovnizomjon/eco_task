import pytest

from apps.chat.models import Message
from apps.notifications.models import Notification
from tests.conftest import api_as

pytestmark = pytest.mark.django_db
C = "/api/v1/conversations/"


def open_dm(user, other):
    return api_as(user).post(C, {"kind": "DIRECT", "user": other.pk}, format="json")


def send(user, conv, body="hi", **extra):
    return api_as(user).post(f"{C}{conv}/messages/", {"body": body, **extra}, format="json")


def test_direct_rules(owner, assistant, worker, worker2, client_user):
    assert open_dm(assistant, worker).status_code == 201
    assert open_dm(client_user, assistant).status_code == 201
    assert open_dm(worker, owner).status_code == 201
    assert open_dm(worker, worker2).status_code == 403  # workers cannot DM each other
    assert open_dm(worker, client_user).status_code == 403
    assert open_dm(owner, owner).status_code == 403


def test_direct_is_reused(owner, worker):
    a, b = open_dm(owner, worker).data["id"], open_dm(worker, owner).data["id"]
    assert a == b


def test_non_member_cannot_read_or_write_by_guessing_id(owner, worker, worker2, assistant):
    conv = open_dm(owner, worker).data["id"]
    send(owner, conv, "private")
    for outsider in (worker2, assistant):
        assert api_as(outsider).get(f"{C}{conv}/").status_code == 404
        assert api_as(outsider).get(f"{C}{conv}/messages/").status_code == 404
        assert send(outsider, conv).status_code == 404
        assert api_as(outsider).post(f"{C}{conv}/read/", {"message_id": 1}, format="json").status_code == 404
    assert Message.objects.count() == 1


def test_history_pagination_and_cursor(owner, worker):
    conv = open_dm(owner, worker).data["id"]
    for i in range(7):
        send(owner, conv, f"m{i}")
    page1 = api_as(worker).get(f"{C}{conv}/messages/", {"limit": 3}).data
    assert [m["body"] for m in page1["results"]] == ["m6", "m5", "m4"] and page1["has_more"]
    page2 = api_as(worker).get(f"{C}{conv}/messages/", {"limit": 10, "before": page1["results"][-1]["id"]}).data
    assert [m["body"] for m in page2["results"]] == ["m3", "m2", "m1", "m0"] and not page2["has_more"]
    assert api_as(worker).get(f"{C}{conv}/messages/", {"limit": "x"}).status_code == 400


def test_message_validation(owner, worker):
    conv = open_dm(owner, worker).data["id"]
    assert send(owner, conv, "   ").status_code == 400
    assert send(owner, conv, "x" * 4001).status_code == 400


def test_idempotent_send(owner, worker):
    conv = open_dm(owner, worker).data["id"]
    first = send(owner, conv, "once", client_msg_id="abc")
    second = send(owner, conv, "once", client_msg_id="abc")
    assert first.status_code == 201 and second.status_code == 200 and first.data["id"] == second.data["id"]
    assert Message.objects.count() == 1


def test_unread_counts_and_read_receipts(owner, worker):
    conv = open_dm(owner, worker).data["id"]
    send(owner, conv, "a")
    last = send(owner, conv, "b").data["id"]
    listing = api_as(worker).get(C).data
    assert listing[0]["unread_count"] == 2 and listing[0]["last_message"]["body"] == "b"
    assert api_as(owner).get(C).data[0]["unread_count"] == 0  # own messages never unread
    assert api_as(worker).post(f"{C}{conv}/read/", {"message_id": last}, format="json").data["last_read_message_id"] == last
    assert api_as(worker).get(C).data[0]["unread_count"] == 0
    members = {m["id"]: m["last_read_message_id"] for m in api_as(owner).get(f"{C}{conv}/").data["members"]}
    assert members[worker.pk] == last


def test_message_creates_content_free_notification(owner, worker):
    conv = open_dm(owner, worker).data["id"]
    send(owner, conv, "top secret text")
    n = Notification.objects.get(user=worker)
    assert n.kind == "chat.message" and "top secret" not in n.title
    assert not Notification.objects.filter(user=owner).exists()


def test_group_membership_and_removal(owner, assistant, worker, worker2):
    r = api_as(assistant).post(C, {"kind": "GROUP", "title": "Crew", "member_ids": [worker.pk]}, format="json")
    assert r.status_code == 201
    gid = r.data["id"]
    assert send(worker, gid, "hello").status_code == 201
    assert api_as(worker2).get(f"{C}{gid}/").status_code == 404
    assert api_as(worker).post(f"{C}{gid}/members/", {"user_ids": [worker2.pk]}, format="json").status_code == 403
    assert api_as(assistant).post(f"{C}{gid}/members/", {"user_ids": [worker2.pk]}, format="json").status_code == 200
    assert send(worker2, gid).status_code == 201
    assert api_as(assistant).delete(f"{C}{gid}/members/{worker2.pk}/").status_code == 204
    assert send(worker2, gid).status_code == 404 and api_as(worker2).get(f"{C}{gid}/messages/").status_code == 404
    assert api_as(worker).delete(f"{C}{gid}/members/{worker.pk}/").status_code == 204  # may leave voluntarily


def test_workers_and_clients_cannot_create_groups(worker, client_user):
    for u in (worker, client_user):
        assert api_as(u).post(C, {"kind": "GROUP", "title": "x"}, format="json").status_code == 403


def test_task_chat_follows_task_visibility(owner, worker, worker2, client_user, client2):
    t = api_as(owner).post(
        "/api/v1/tasks/", {"title": "T", "worker_ids": [worker.pk], "client": client_user.pk}, format="json"
    ).data["id"]
    conv = api_as(worker).post(C, {"kind": "TASK", "task": t}, format="json").data["id"]
    assert api_as(client_user).post(C, {"kind": "TASK", "task": t}, format="json").data["id"] == conv
    assert api_as(worker2).post(C, {"kind": "TASK", "task": t}, format="json").status_code == 404
    assert api_as(client2).get(f"{C}{conv}/").status_code == 404
    assert send(client_user, conv, "when?").status_code == 201
    api_as(owner).put(f"/api/v1/tasks/{t}/assignees/", {"worker_ids": []}, format="json")
    assert api_as(worker).get(f"{C}{conv}/messages/").status_code == 404  # unassigned -> access gone immediately


def test_client_does_not_see_other_clients_in_group(owner, client_user, client2):
    gid = api_as(owner).post(
        C, {"kind": "GROUP", "title": "Clients", "member_ids": [client_user.pk, client2.pk]}, format="json"
    ).data["id"]
    names = {m["username"] for m in api_as(client_user).get(f"{C}{gid}/").data["members"]}
    assert "client2" not in names and "client" in names and "owner" in names
