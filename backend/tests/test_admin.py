import pytest
from django.conf import settings
from django.test import Client

from apps.audit.models import AuditLog

from .conftest import PASSWORD

ADMIN = "/" + settings.ADMIN_URL


def login(username: str) -> tuple[Client, int]:
    client = Client()
    response = client.post(ADMIN + "login/", {"username": username, "password": PASSWORD, "next": ADMIN})
    return client, response.status_code


@pytest.mark.parametrize("who", ["assistant", "worker", "client_user"])
def test_only_the_owner_can_sign_in_to_the_admin(who, request):
    user = request.getfixturevalue(who)
    client, status = login(user.username)
    assert status == 200  # login form re-rendered with the generic error, no redirect
    assert client.get(ADMIN).status_code == 302


def test_owner_browses_every_registered_model(owner):
    client, status = login(owner.username)
    assert status == 302
    for path in ("", "accounts/user/", "accounts/authtoken/", "audit/auditlog/", "tasks/task/", "projects/project/"):
        assert client.get(ADMIN + path).status_code == 200


def test_audit_log_is_read_only_in_the_admin(owner):
    client, _ = login(owner.username)
    assert client.get(ADMIN + "audit/auditlog/add/").status_code == 403


def test_owner_cannot_change_their_own_role(owner):
    client, _ = login(owner.username)
    page = client.get(f"{ADMIN}accounts/user/{owner.pk}/change/")
    assert b'name="role"' not in page.content


def test_admin_edit_is_audited_without_values(owner, worker):
    client, _ = login(owner.username)
    response = client.post(
        f"{ADMIN}accounts/user/{worker.pk}/change/",
        {"username": worker.username, "full_name": "New Name", "email": "", "phone": "", "role": "WORKER", "is_active": "on"},
    )
    assert response.status_code == 302
    entry = AuditLog.objects.get(action="admin.user.changed")
    assert entry.metadata == {"fields": ["full_name"]}
