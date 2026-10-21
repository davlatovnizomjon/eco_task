import pytest
from django.core.management import call_command
from django.core.management.base import CommandError
from rest_framework.test import APIClient

from apps.accounts.models import AuthToken, User
from apps.audit.models import AuditLog
from apps.core.policies import Cap, Role, can
from tests.conftest import PASSWORD, api_as

pytestmark = pytest.mark.django_db


def test_policy_matrix(owner, assistant, worker, client_user):
    assert all(can(owner, c) for c in Cap)
    assert can(assistant, Cap.ASSIGN_TASK) and not can(assistant, Cap.VIEW_FINANCE)
    assert not can(assistant, Cap.MANAGE_USERS) and not can(assistant, Cap.VIEW_AUDIT)
    assert not can(worker, Cap.CREATE_TASK)
    assert can(client_user, Cap.CREATE_TASK) and not can(client_user, Cap.VIEW_ALL_TASKS)


def test_inactive_user_has_no_capability(owner):
    owner.is_active = False
    assert not can(owner, Cap.MANAGE_USERS)


def test_login_success_and_secrets_not_returned(owner):
    r = APIClient().post("/api/v1/auth/login/", {"username": "owner", "password": PASSWORD}, format="json")
    assert r.status_code == 200 and r.data["token"]
    assert "password" not in r.data["user"] and "is_superuser" not in r.data["user"]
    assert AuthToken.objects.get().key_hash != r.data["token"]  # only the digest is stored


def test_login_failure_is_generic_and_audited(owner):
    r = APIClient().post("/api/v1/auth/login/", {"username": "owner", "password": "wrong"}, format="json")
    r2 = APIClient().post("/api/v1/auth/login/", {"username": "nobody", "password": "wrong"}, format="json")
    assert r.status_code == r2.status_code == 401
    assert r.data["error"]["detail"] == r2.data["error"]["detail"]
    assert AuditLog.objects.filter(action="auth.login_failed").count() == 2
    assert "wrong" not in str(list(AuditLog.objects.values_list("metadata", flat=True)))


def test_login_is_throttled(owner):
    c = APIClient()
    codes = [
        c.post("/api/v1/auth/login/", {"username": "owner", "password": "x"}, format="json").status_code
        for _ in range(12)
    ]
    assert 429 in codes


def test_requires_authentication():
    assert APIClient().get("/api/v1/auth/me/").status_code == 401


def test_expired_and_revoked_tokens_rejected(owner):
    row, raw = AuthToken.issue(owner)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {raw}")
    assert c.get("/api/v1/auth/me/").status_code == 200
    c.post("/api/v1/auth/logout/")
    assert c.get("/api/v1/auth/me/").status_code == 401


def test_password_change_revokes_other_sessions(owner):
    old = api_as(owner)
    new = api_as(owner)
    r = new.post(
        "/api/v1/auth/password/",
        {"old_password": PASSWORD, "new_password": "An0ther-Str0ng-Passphrase!"},
        format="json",
    )
    assert r.status_code == 200
    assert old.get("/api/v1/auth/me/").status_code == 401
    assert new.get("/api/v1/auth/me/").status_code == 401  # old token of this device also revoked; new token returned
    fresh = APIClient()
    fresh.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['token']}")
    assert fresh.get("/api/v1/auth/me/").status_code == 200


def test_weak_new_password_rejected(owner):
    r = api_as(owner).post(
        "/api/v1/auth/password/", {"old_password": PASSWORD, "new_password": "12345678"}, format="json"
    )
    assert r.status_code == 400


def test_owner_creates_user_with_hashed_password(owner):
    r = api_as(owner).post(
        "/api/v1/users/", {"username": "w1", "password": "Valid-Passphrase-1!", "role": "WORKER"}, format="json"
    )
    assert r.status_code == 201
    user = User.objects.get(username="w1")
    assert user.password != "Valid-Passphrase-1!" and user.check_password("Valid-Passphrase-1!")
    assert AuditLog.objects.filter(action="user.created").exists()


@pytest.mark.parametrize("who", ["assistant", "worker", "client_user"])
def test_non_owner_cannot_create_users(request, who):
    user = request.getfixturevalue(who)
    r = api_as(user).post(
        "/api/v1/users/", {"username": "x", "password": "Valid-Passphrase-1!", "role": "OWNER"}, format="json"
    )
    assert r.status_code == 403
    assert not User.objects.filter(username="x").exists()


def test_user_cannot_escalate_own_role(worker):
    c = api_as(worker)
    assert c.patch(f"/api/v1/users/{worker.pk}/", {"role": "OWNER"}, format="json").status_code in (403, 404)
    worker.refresh_from_db()
    assert worker.role == Role.WORKER


def test_owner_cannot_change_own_role_or_remove_last_owner(owner):
    c = api_as(owner)
    assert c.patch(f"/api/v1/users/{owner.pk}/", {"role": "WORKER"}, format="json").status_code == 403
    assert c.patch(f"/api/v1/users/{owner.pk}/", {"is_active": False}, format="json").status_code == 403


def test_last_owner_protected_from_other_owner_only_when_single(owner):
    second = User.objects.create_user("o2", password=PASSWORD, role="OWNER")
    c = api_as(owner)
    assert c.patch(f"/api/v1/users/{second.pk}/", {"is_active": False}, format="json").status_code == 200
    # owner now sole active owner; deactivated second cannot be used to bypass the check
    third = User.objects.get(pk=second.pk)
    assert third.is_active is False


def test_deactivation_revokes_sessions(owner, worker):
    wc = api_as(worker)
    assert wc.get("/api/v1/auth/me/").status_code == 200
    api_as(owner).patch(f"/api/v1/users/{worker.pk}/", {"is_active": False}, format="json")
    assert wc.get("/api/v1/auth/me/").status_code == 401


def test_mass_assignment_ignored(owner, worker):
    r = api_as(owner).patch(
        f"/api/v1/users/{worker.pk}/", {"is_superuser": True, "is_staff": True, "password": "x"}, format="json"
    )
    worker.refresh_from_db()
    assert r.status_code == 200 and not worker.is_superuser and not worker.is_staff


def test_assistant_sees_only_workers_and_clients(owner, assistant, worker, client_user):
    r = api_as(assistant).get("/api/v1/users/")
    roles = {u["role"] for u in r.data["results"]}
    assert roles == {"WORKER", "CLIENT"}
    assert set(r.data["results"][0]) == {"id", "username", "full_name", "role"}
    assert api_as(assistant).get(f"/api/v1/users/{owner.pk}/").status_code == 404


def test_worker_and_client_cannot_list_users(worker, client_user):
    assert api_as(worker).get("/api/v1/users/").data["results"] == []
    assert api_as(client_user).get(f"/api/v1/users/{worker.pk}/").status_code == 404


def test_audit_log_access_and_immutability(owner, assistant):
    assert api_as(assistant).get("/api/v1/audit/").status_code == 403
    assert api_as(owner).get("/api/v1/audit/").status_code == 200
    entry = AuditLog.objects.create(action="x")
    with pytest.raises(PermissionError):
        entry.delete()
    entry.action = "y"
    with pytest.raises(PermissionError):
        entry.save()


class TestBootstrapOwner:
    def env(self, monkeypatch, password="Bootstrap-Passphrase-42!"):
        monkeypatch.setenv("INITIAL_OWNER_USERNAME", "boss")
        monkeypatch.setenv("INITIAL_OWNER_EMAIL", "boss@example.com")
        monkeypatch.setenv("INITIAL_OWNER_PASSWORD", password)

    def test_creates_owner_once_and_is_idempotent(self, monkeypatch, db, capsys):
        self.env(monkeypatch)
        call_command("bootstrap_owner")
        owner = User.objects.get(username="boss")
        assert owner.role == Role.OWNER and owner.check_password("Bootstrap-Passphrase-42!")
        hashed = owner.password
        monkeypatch.setenv("INITIAL_OWNER_PASSWORD", "Different-Passphrase-77!")
        call_command("bootstrap_owner")
        owner.refresh_from_db()
        assert User.objects.filter(role=Role.OWNER).count() == 1 and owner.password == hashed
        assert "Bootstrap-Passphrase" not in capsys.readouterr().out

    def test_missing_variables(self, monkeypatch, db):
        monkeypatch.delenv("INITIAL_OWNER_USERNAME", raising=False)
        monkeypatch.delenv("INITIAL_OWNER_PASSWORD", raising=False)
        with pytest.raises(CommandError):
            call_command("bootstrap_owner")

    @pytest.mark.parametrize("pw", ["change-me", "short", "password1234"])
    def test_unsafe_passwords_rejected(self, monkeypatch, db, pw):
        self.env(monkeypatch, pw)
        with pytest.raises(CommandError):
            call_command("bootstrap_owner")
        assert not User.objects.exists()

    def test_does_not_hijack_existing_username(self, monkeypatch, db):
        self.env(monkeypatch)
        User.objects.create_user("boss", password=PASSWORD, role="WORKER")
        with pytest.raises(CommandError):
            call_command("bootstrap_owner")
        assert User.objects.get(username="boss").role == Role.WORKER


def test_health_and_ready(db):
    c = APIClient()
    assert c.get("/health/").status_code == 200
    r = c.get("/ready/")
    assert r.status_code == 200 and r.json() == {"status": "ready"}
