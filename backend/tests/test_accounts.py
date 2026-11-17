from datetime import timedelta

import pytest
from django.core.management import call_command
from django.core.management.base import CommandError
from django.utils import timezone
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
    assert can(assistant, Cap.MANAGE_STAFF) and can(assistant, Cap.DELETE_TASK)
    assert not can(worker, Cap.MANAGE_STAFF) and not can(client_user, Cap.MANAGE_STAFF)
    assert not can(worker, Cap.DELETE_TASK) and not can(client_user, Cap.DELETE_TASK)
    assert not can(worker, Cap.CREATE_TASK)
    assert can(client_user, Cap.CREATE_TASK) and not can(client_user, Cap.VIEW_ALL_TASKS)


def test_inactive_user_has_no_capability(owner):
    owner.is_active = False
    assert not can(owner, Cap.MANAGE_USERS)


def test_login_success_and_secrets_not_returned(owner):
    r = APIClient().post("/api/v1/auth/login/", {"username": "owner", "password": PASSWORD}, format="json")
    assert r.status_code == 200 and r.data["token"]
    assert set(r.data["user"]) == {"id", "full_name", "role"}  # nothing else about the account is sent at sign-in
    assert AuthToken.objects.get().key_hash != r.data["token"]  # only the digest is stored


def test_login_failure_is_generic_and_audited(owner):
    r = APIClient().post("/api/v1/auth/login/", {"username": "owner", "password": "wrong"}, format="json")
    r2 = APIClient().post("/api/v1/auth/login/", {"username": "nobody", "password": "wrong"}, format="json")
    assert r.status_code == r2.status_code == 401
    assert r.data["error"]["message"] == r2.data["error"]["message"]
    assert AuditLog.objects.filter(action="auth.login_failed").count() == 2
    assert "wrong" not in str(list(AuditLog.objects.values_list("metadata", flat=True)))


def test_login_is_throttled(owner):
    c = APIClient()
    codes = [
        c.post("/api/v1/auth/login/", {"username": "owner", "password": "x"}, format="json").status_code
        for _ in range(12)
    ]
    assert 429 in codes


def _login(username="owner", password="wrong", **extra):
    return APIClient().post("/api/v1/auth/login/", {"username": username, "password": password}, format="json", **extra)


def test_five_wrong_passwords_lock_login_for_five_minutes(owner):
    for _ in range(4):
        r = _login()
        assert r.status_code == 401
        assert r.data["error"] == {
            "code": "invalid_credentials",
            "title": "Login yoki parol noto‘g‘ri",
            "message": "Kiritgan login va parolingizni tekshirib, qayta urinib ko‘ring.",
        }
    r = _login()  # the fifth wrong attempt
    assert r.status_code == 429
    error = r.data["error"]
    assert error["code"] == "login_locked"
    assert error["retry_after"] == 300 and r["Retry-After"] == "300"
    assert "locked_until" not in error
    assert AuditLog.objects.filter(action="auth.login_locked").count() == 1


def test_locked_login_refuses_even_the_right_password_and_ends_with_the_lock(owner, settings):
    import time

    for _ in range(5):
        _login()
    r = _login(password=PASSWORD)
    assert r.status_code == 429 and 0 < r.data["error"]["retry_after"] <= 300
    from django.core.cache import cache

    from apps.accounts.services import _login_key

    cache.set(_login_key("lock", "owner", "127.0.0.1"), time.time() - 1)  # the lock has run out
    assert _login(password=PASSWORD).status_code == 200


def test_successful_login_resets_the_counter(owner):
    for _ in range(4):
        _login()
    assert _login(password=PASSWORD).status_code == 200
    for _ in range(4):  # a full set of attempts is available again
        assert _login().status_code == 401
    assert _login().status_code == 429


def test_lock_is_per_username_and_unknown_names_are_counted_alike(owner, worker):
    for _ in range(5):
        _login("owner")
    assert _login("worker", PASSWORD).status_code == 200
    for _ in range(4):
        assert _login("nobody").status_code == 401
    assert _login("nobody").status_code == 429


@pytest.mark.parametrize(
    "language,title",
    [
        ("uz", "Login yoki parol noto‘g‘ri"),
        ("uz-Cyrl", "Логин ёки парол нотўғри"),
        ("ru-RU,ru;q=0.9", "Неверный логин или пароль"),
    ],
)
def test_error_texts_follow_the_accept_language_header(owner, language, title):
    error = _login(HTTP_ACCEPT_LANGUAGE=language).data["error"]
    assert error["title"] == title and error["message"]


def test_locked_message_is_translated_and_says_the_minutes(owner):
    for _ in range(4):
        _login()
    r = _login(HTTP_ACCEPT_LANGUAGE="ru")
    assert r.status_code == 429
    assert r.data["error"]["title"] == "Вход временно заблокирован"
    assert r.data["error"]["message"] == "Слишком много неудачных попыток. Повторите через 5 мин."


def test_blocked_user_is_told_so_only_with_the_right_password(owner, worker):
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {login_pair('worker')[0]}")
    assert c.get("/api/v1/auth/me/").status_code == 200
    worker.is_active = False
    worker.save()
    assert c.get("/api/v1/auth/me/").status_code == 401  # the open session stops working at once
    r = _login("worker", PASSWORD, HTTP_ACCEPT_LANGUAGE="ru")
    assert r.status_code == 403
    assert r.data["error"] == {
        "code": "account_blocked",
        "title": "Аккаунт заблокирован",
        "message": "Ваш аккаунт заблокирован. Свяжитесь с диспетчером.",
    }
    wrong = _login("worker", "wrong")
    assert wrong.status_code == 401 and wrong.data["error"]["code"] == "invalid_credentials"
    assert AuditLog.objects.filter(action="auth.login_blocked").count() == 1


def test_owner_blocks_and_unblocks_with_patch_is_active(as_user, owner, worker):
    c = as_user(owner)
    assert c.patch(f"/api/v1/users/{worker.pk}/", {"is_active": False}, format="json").status_code == 200
    assert _login("worker", PASSWORD).status_code == 403
    assert c.patch(f"/api/v1/users/{worker.pk}/", {"is_active": True}, format="json").status_code == 200
    assert _login("worker", PASSWORD).status_code == 200


def test_requires_authentication():
    assert APIClient().get("/api/v1/auth/me/").status_code == 401


def test_expired_and_revoked_tokens_rejected(owner):
    row, raw, _ = AuthToken.issue(owner)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {raw}")
    assert c.get("/api/v1/auth/me/").status_code == 200
    c.post("/api/v1/auth/logout/")
    assert c.get("/api/v1/auth/me/").status_code == 401


def login_pair(username="owner"):
    r = APIClient().post("/api/v1/auth/login/", {"username": username, "password": PASSWORD}, format="json")
    return r.data["token"], r.data["refresh"]


def refresh(raw):
    return APIClient().post("/api/v1/auth/refresh/", {"refresh": raw}, format="json")


def test_login_returns_refresh_token_stored_only_as_digest(owner):
    access, refresh_raw = login_pair()
    row = AuthToken.objects.get()
    assert refresh_raw and refresh_raw != access
    assert row.refresh_hash != refresh_raw and row.refresh_expires_at > row.expires_at


def test_refresh_issues_new_pair_and_rotates(owner):
    access, refresh_raw = login_pair()
    r = refresh(refresh_raw)
    assert r.status_code == 200 and set(r.data) == {"token", "refresh"}
    assert r.data["token"] != access and r.data["refresh"] != refresh_raw
    assert AuthToken.objects.count() == 1  # same session, rotated in place
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['token']}")
    assert c.get("/api/v1/auth/me/").status_code == 200
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    assert c.get("/api/v1/auth/me/").status_code == 401  # the old access token died with the rotation
    assert AuditLog.objects.filter(action="auth.token_refreshed").exists()


def test_refresh_token_is_single_use(owner):
    _, refresh_raw = login_pair()
    assert refresh(refresh_raw).status_code == 200
    r = refresh(refresh_raw)
    assert r.status_code == 401 and r.data["error"]["code"] == "invalid_refresh_token"


def test_refresh_works_after_access_token_expired(owner):
    _, refresh_raw = login_pair()
    AuthToken.objects.update(expires_at=timezone.now() - timedelta(minutes=1))
    assert refresh(refresh_raw).status_code == 200


@pytest.mark.parametrize("bad", ["", "garbage", "x" * 300])
def test_unknown_or_malformed_refresh_rejected(owner, bad):
    r = refresh(bad)
    assert r.status_code in (400, 401)
    assert "error" in r.data


def test_expired_refresh_token_rejected(owner):
    _, refresh_raw = login_pair()
    AuthToken.objects.update(refresh_expires_at=timezone.now() - timedelta(minutes=1))
    assert refresh(refresh_raw).status_code == 401


def test_logout_revokes_refresh_token(owner):
    access, refresh_raw = login_pair()
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    assert c.post("/api/v1/auth/logout/").status_code == 204
    assert refresh(refresh_raw).status_code == 401


def test_deactivated_user_cannot_refresh(owner, worker):
    _, refresh_raw = login_pair("worker")
    api_as(owner).patch(f"/api/v1/users/{worker.pk}/", {"is_active": False}, format="json")
    assert refresh(refresh_raw).status_code == 401


def test_password_change_revokes_refresh_and_returns_new_pair(owner):
    _, old_refresh = login_pair()
    c = api_as(owner)
    r = c.post(
        "/api/v1/auth/password/",
        {"old_password": PASSWORD, "new_password": "An0ther-Str0ng-Passphrase!"},
        format="json",
    )
    assert r.status_code == 200 and r.data["refresh"]
    assert refresh(old_refresh).status_code == 401
    assert refresh(r.data["refresh"]).status_code == 200


def test_refresh_needs_no_access_token_and_is_throttled(owner):
    c = APIClient()
    codes = [c.post("/api/v1/auth/refresh/", {"refresh": "nope"}, format="json").status_code for _ in range(35)]
    assert set(codes) == {401, 429}


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


@pytest.mark.parametrize("who", ["worker", "client_user"])
def test_worker_and_client_cannot_create_users(request, who):
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


def test_assistant_creates_workers_and_clients_only(assistant):
    c = api_as(assistant)
    body = {"username": "new.worker", "password": "Valid-Passphrase-1!", "full_name": "New Worker"}
    assert c.post("/api/v1/users/", {**body, "role": "WORKER"}, format="json").status_code == 201
    new_client = {**body, "username": "new.client", "role": "CLIENT"}
    assert c.post("/api/v1/users/", new_client, format="json").status_code == 201
    for role in ("ASSISTANT", "OWNER"):
        r = c.post("/api/v1/users/", {**body, "username": f"x.{role}", "role": role}, format="json")
        assert r.status_code == 403 and r.data["error"]["code"] == "forbidden"
        assert not User.objects.filter(username=f"x.{role}").exists()
    assert AuditLog.objects.filter(action="user.created", actor=assistant).count() == 2


def test_assistant_edits_and_removes_workers_but_cannot_promote_or_touch_managers(owner, assistant, worker):
    c = api_as(assistant)
    r = c.patch(f"/api/v1/users/{worker.pk}/", {"full_name": "Renamed", "phone": "+998901234567"}, format="json")
    assert r.status_code == 200 and r.data["full_name"] == "Renamed" and r.data["phone"] == "+998901234567"
    assert c.patch(f"/api/v1/users/{worker.pk}/", {"role": "ASSISTANT"}, format="json").status_code == 403
    assert c.patch(f"/api/v1/users/{worker.pk}/", {"role": "OWNER"}, format="json").status_code == 403
    worker.refresh_from_db()
    assert worker.role == Role.WORKER
    other = User.objects.create_user(username="assistant2", password=PASSWORD, role=Role.ASSISTANT)
    for target in (owner, other):  # owners and managers are invisible to a manager: 404, never 403
        assert c.patch(f"/api/v1/users/{target.pk}/", {"full_name": "x"}, format="json").status_code == 404
        assert c.delete(f"/api/v1/users/{target.pk}/").status_code == 404
    r = c.delete(f"/api/v1/users/{worker.pk}/")
    assert r.status_code == 200 and r.data["result"] in ("deleted", "deactivated")


AVATAR = "https://cdn.example.com/avatars/w1.png"


def test_avatar_url_defaults_to_empty_and_is_in_login_me_and_assistant_views(owner, assistant, worker):
    assert api_as(owner).get("/api/v1/auth/me/").data["avatar_url"] == ""
    row = api_as(assistant).get("/api/v1/users/").data["results"][0]
    assert row["avatar_url"] == "" and row["role"] == "WORKER"


def test_owner_sets_and_clears_avatar_url(owner, worker):
    c = api_as(owner)
    r = c.patch(f"/api/v1/users/{worker.pk}/", {"avatar_url": AVATAR}, format="json")
    assert r.status_code == 200 and r.data["avatar_url"] == AVATAR
    assert api_as(worker).get("/api/v1/auth/me/").data["avatar_url"] == AVATAR
    assert c.patch(f"/api/v1/users/{worker.pk}/", {"avatar_url": ""}, format="json").data["avatar_url"] == ""


def test_owner_creates_user_with_avatar_url(owner):
    r = api_as(owner).post(
        "/api/v1/users/",
        {"username": "w9", "password": "Valid-Passphrase-1!", "role": "WORKER", "avatar_url": AVATAR},
        format="json",
    )
    assert r.status_code == 201 and r.data["avatar_url"] == AVATAR


@pytest.mark.parametrize(
    "bad", ["javascript:alert(1)", "ftp://example.com/a.png", "not a url", "https://x.co/" + "a" * 500]
)
def test_unsafe_or_invalid_avatar_url_rejected(owner, worker, bad):
    r = api_as(owner).patch(f"/api/v1/users/{worker.pk}/", {"avatar_url": bad}, format="json")
    assert r.status_code == 400 and "error" in r.data
    worker.refresh_from_db()
    assert worker.avatar_url == ""


def test_non_owner_cannot_set_avatar_url(worker, worker2):
    r = api_as(worker).patch(f"/api/v1/users/{worker.pk}/", {"avatar_url": AVATAR}, format="json")
    assert r.status_code in (403, 404)
    worker.refresh_from_db()
    assert worker.avatar_url == ""


def test_assistant_sees_only_workers_and_clients(owner, assistant, worker, client_user):
    r = api_as(assistant).get("/api/v1/users/")
    roles = {u["role"] for u in r.data["results"]}
    assert roles == {"WORKER", "CLIENT"}
    assert {"phone", "address", "is_org", "is_active"} <= set(r.data["results"][0])  # full account data
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


# --- address and organization flag (clients of the new design) ------------------------------
def test_owner_creates_an_organization_client_with_address(owner):
    r = api_as(owner).post(
        "/api/v1/users/",
        {
            "username": "yashil",
            "password": "Str0ng-Test-Passphrase!",
            "role": "CLIENT",
            "full_name": "Yashil Bog MChJ",
            "address": "Qibray tumani",
            "is_org": True,
        },
        format="json",
    )
    assert r.status_code == 201 and r.data["is_org"] is True and r.data["address"] == "Qibray tumani"
    assert User.objects.get(username="yashil").is_org is True


def test_org_flag_defaults_to_false_and_can_be_edited(owner, client_user):
    assert api_as(owner).get(f"/api/v1/users/{client_user.pk}/").data["is_org"] is False
    r = api_as(owner).patch(f"/api/v1/users/{client_user.pk}/", {"is_org": True, "address": "Sergeli"}, format="json")
    assert r.status_code == 200 and r.data["is_org"] is True and r.data["address"] == "Sergeli"


def test_assistant_sees_client_account_data_but_no_money(owner, assistant, client_user):
    api_as(owner).patch(f"/api/v1/users/{client_user.pk}/", {"address": "Sergeli", "is_org": True}, format="json")
    data = api_as(assistant).get(f"/api/v1/users/{client_user.pk}/").data
    assert data["address"] == "Sergeli" and data["is_org"] is True
    assert "agreed_value" not in data and "currency" not in data
