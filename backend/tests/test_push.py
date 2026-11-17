import pytest

from apps.notifications import push
from apps.notifications.models import DeviceToken
from apps.notifications.services import notify

pytestmark = pytest.mark.django_db

URL = "/api/v1/notifications/devices/"


def test_register_is_idempotent_and_moves_a_token_between_users(as_user, worker, worker2):
    body = {"token": "tok-1", "platform": "ios", "language": "ru"}
    assert as_user(worker).post(URL, body, format="json").status_code == 204
    assert as_user(worker).post(URL, body, format="json").status_code == 204
    assert DeviceToken.objects.filter(user=worker).count() == 1
    assert as_user(worker2).post(URL, body, format="json").status_code == 204
    assert DeviceToken.objects.get(token="tok-1").user == worker2


def test_register_validates_input(as_user, worker):
    assert as_user(worker).post(URL, {}, format="json").status_code == 400
    assert as_user(worker).post(URL, {"token": "t", "platform": "tv"}, format="json").status_code == 400


def test_requires_authentication(client):
    assert client.post(URL, {"token": "t"}, format="json").status_code in (401, 403)


def test_unregister_only_removes_own_tokens(as_user, worker, worker2):
    DeviceToken.objects.create(user=worker, token="mine", platform="ios")
    DeviceToken.objects.create(user=worker2, token="theirs", platform="ios")
    assert as_user(worker).delete(URL, {"token": "theirs"}, format="json").status_code == 204
    assert DeviceToken.objects.filter(token="theirs").exists()
    assert as_user(worker).delete(URL, {"token": "mine"}, format="json").status_code == 204
    assert not DeviceToken.objects.filter(token="mine").exists()
    assert as_user(worker).delete(URL, {}, format="json").status_code == 400


def test_notify_queues_a_push_only_when_firebase_is_configured(settings, worker, monkeypatch):
    calls = []
    monkeypatch.setattr(push, "_executor", type("E", (), {"submit": lambda self, fn, *a: calls.append(a)})())
    settings.FIREBASE_CREDENTIALS_FILE = ""
    notify([worker], "task.assigned", "New task")
    assert calls == []
    settings.FIREBASE_CREDENTIALS_FILE = "service-account.json"
    with pytest.MonkeyPatch.context() as m:
        m.setattr(push.transaction, "on_commit", lambda fn: fn())
        notify([worker], "task.assigned", "New task")
    assert calls and calls[0][1] == "New task" and calls[0][2] == {"kind": "task.assigned"}
