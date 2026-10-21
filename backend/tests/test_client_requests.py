import pytest

from apps.audit.models import AuditLog
from apps.core.policies import Cap, can
from apps.notifications.models import Notification

pytestmark = pytest.mark.django_db
R = "/api/v1/requests/"
BODY = {"title": "Deliver 50 saplings", "address": "Yunusobod, 17", "kind": "DELIVERY", "slot": "09:00–12:00"}


def file(as_user, client_user, **extra):
    r = as_user(client_user).post(R, {**BODY, **extra}, format="json")
    assert r.status_code == 201, r.data
    return r.data


def test_policy_for_requests(owner, assistant, worker, client_user):
    assert can(client_user, Cap.CREATE_REQUEST) and not can(client_user, Cap.MANAGE_REQUESTS)
    assert can(assistant, Cap.MANAGE_REQUESTS) and not can(assistant, Cap.CREATE_REQUEST)
    assert not can(worker, Cap.CREATE_REQUEST) and not can(worker, Cap.MANAGE_REQUESTS)


def test_client_files_request_and_staff_is_notified(as_user, client_user, owner, assistant, worker):
    data = file(as_user, client_user)
    assert data["status"] == "ACCEPTED" and data["code"] == f"R-{data['id']}"
    assert data["client"]["id"] == client_user.pk
    assert set(Notification.objects.filter(kind="request.created").values_list("user_id", flat=True)) == {
        owner.pk,
        assistant.pk,
    }
    assert AuditLog.objects.filter(action="request.created").count() == 1


def test_only_clients_can_file(as_user, owner, worker):
    for user in (owner, worker):
        r = as_user(user).post(R, BODY, format="json")
        assert r.status_code == 403 and r.data["error"]["code"] == "forbidden"


def test_validation(as_user, client_user):
    r = as_user(client_user).post(R, {"title": "x"}, format="json")
    assert r.status_code == 400 and "address" in r.data["error"]["detail"]


def test_visibility_and_idor(as_user, client_user, client2, assistant, worker):
    mine = file(as_user, client_user)
    assert [x["id"] for x in as_user(client_user).get(R).data["results"]] == [mine["id"]]
    assert as_user(client2).get(R).data["count"] == 0
    assert as_user(client2).get(f"{R}{mine['id']}/").status_code == 404
    assert as_user(worker).get(f"{R}{mine['id']}/").status_code == 404
    assert as_user(assistant).get(f"{R}{mine['id']}/").status_code == 200


def test_staff_moves_status_forward_only_and_client_is_notified(as_user, client_user, assistant, worker):
    req = file(as_user, client_user)
    url = f"{R}{req['id']}/"
    r = as_user(assistant).patch(
        url, {"status": "PLANNED", "assignee": worker.pk, "date": "2026-11-01", "slot": "12:00–15:00"}, format="json"
    )
    assert r.status_code == 200 and r.data["status"] == "PLANNED" and r.data["assignee"]["id"] == worker.pk
    assert Notification.objects.filter(user=client_user, kind="request.status").count() == 1
    back = as_user(assistant).patch(url, {"status": "ACCEPTED"}, format="json")
    assert back.status_code == 409 and back.data["error"]["code"] == "invalid_transition"
    assert as_user(assistant).patch(url, {"status": "DONE"}, format="json").status_code == 200
    closed = as_user(assistant).patch(url, {"slot": "x"}, format="json")
    assert closed.status_code == 409 and closed.data["error"]["code"] == "request_closed"


def test_client_cannot_change_status_and_assignee_must_be_staff(as_user, client_user, client2, assistant):
    req = file(as_user, client_user)
    url = f"{R}{req['id']}/"
    r = as_user(client_user).patch(url, {"status": "DONE"}, format="json")
    assert r.status_code == 403
    r = as_user(assistant).patch(url, {"assignee": client2.pk}, format="json")
    assert r.status_code == 400 and r.data["error"]["code"] == "invalid_assignee"


def test_messages_flow_both_ways(as_user, client_user, assistant):
    req = file(as_user, client_user)
    url = f"{R}{req['id']}/messages/"
    assert as_user(client_user).post(url, {"body": "When will you come?"}, format="json").status_code == 201
    assert Notification.objects.filter(user=assistant, kind="request.message").count() == 1
    assert as_user(assistant).post(url, {"body": "Tomorrow at 10."}, format="json").status_code == 201
    assert Notification.objects.filter(user=client_user, kind="request.message").count() == 1
    rows = as_user(client_user).get(url).data
    assert [m["body"] for m in rows] == ["When will you come?", "Tomorrow at 10."]
    assert as_user(client_user).post(url, {"body": "   "}, format="json").status_code == 400
