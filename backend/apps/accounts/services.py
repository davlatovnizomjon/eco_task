"""User lifecycle rules. Views stay thin; every rule here is covered by tests."""

import hashlib
import logging
import time

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.cache import cache
from django.db import transaction
from django.db.models import ProtectedError
from django.utils import timezone

from apps.audit.services import record
from apps.core.errors import DomainError
from apps.core.policies import Role, can_manage_account_of

from .models import AuthToken, User, hash_token

logger = logging.getLogger(__name__)


def _login_key(kind: str, username: str, ip: str) -> str:
    """Cache key of a lock/counter. Per (address, username), like `LoginThrottle`, so a stranger cannot lock a victim out
    for everyone. Existing and unknown usernames are counted alike, so the answers never reveal which accounts exist."""
    digest = hashlib.sha256(f"{ip}|{username.lower()[:150]}".encode()).hexdigest()
    return f"login_{kind}:{digest}"


def _locked_error(seconds: int) -> DomainError:
    """429 with the wait in seconds (`retry_after`, also the `Retry-After` header)."""
    seconds = max(1, seconds)
    minutes = -(-seconds // 60)
    return DomainError(
        f"Too many failed attempts. Try again in {minutes} min.",
        "login_locked",
        429,
        {"retry_after": seconds},
    )


def login(username: str, password: str, ip: str = "") -> tuple[User, str, str]:
    lock_key, count_key = _login_key("lock", username, ip), _login_key("count", username, ip)
    locked_until = cache.get(lock_key)
    if locked_until and locked_until > time.time():  # even the right password is refused while the lock lasts
        raise _locked_error(int(locked_until - time.time()))
    user = authenticate(username=username, password=password)
    if user is None:
        # A blocked account with the right password hears why; a wrong password never reveals the account exists.
        blocked = User.objects.filter(username__iexact=username, is_active=False).first()
        if blocked is not None and blocked.check_password(password):
            record(None, "auth.login_blocked", username=username[:150], ip=ip)
            raise DomainError("Your account is blocked. Contact the dispatcher.", "account_blocked", 403)
    if user is None or not user.is_active:
        # Never log the password; the username is enough to spot brute-force patterns.
        record(None, "auth.login_failed", username=username[:150], ip=ip)
        cache.add(count_key, 0, settings.LOGIN_LOCK_SECONDS)
        failures = cache.incr(count_key)
        left = settings.LOGIN_MAX_ATTEMPTS - failures
        if left <= 0:
            cache.set(lock_key, time.time() + settings.LOGIN_LOCK_SECONDS, settings.LOGIN_LOCK_SECONDS)
            cache.delete(count_key)
            record(None, "auth.login_locked", username=username[:150], ip=ip)
            raise _locked_error(settings.LOGIN_LOCK_SECONDS)
        raise DomainError("Invalid username or password.", "invalid_credentials", 401)
    cache.delete(count_key)
    _, access, refresh = AuthToken.issue(user)
    record(user, "auth.login", user)
    return user, access, refresh


@transaction.atomic
def refresh_session(raw_refresh: str) -> tuple[str, str]:
    """Trade a valid refresh token for a new (access, refresh) pair; the presented refresh token stops working."""
    row = (
        AuthToken.objects.select_for_update()
        .select_related("user")
        .filter(refresh_hash=hash_token(raw_refresh))
        .first()
    )
    # One generic answer for unknown, expired, revoked and deactivated-account tokens.
    if row is None or not row.can_refresh or not row.user.is_active:
        raise DomainError("Invalid or expired refresh token.", "invalid_refresh_token", 401)
    pair = row.rotate()
    record(row.user, "auth.token_refreshed", row.user)
    return pair


def revoke_all_tokens(user: User) -> None:
    AuthToken.objects.filter(user=user, revoked_at__isnull=True).update(revoked_at=timezone.now())


def change_password(user: User, old: str, new: str) -> tuple[str, str]:
    """Change the password, revoke every session, and return a fresh (access, refresh) pair for this device."""
    if not user.check_password(old):
        raise DomainError("Current password is incorrect.", "invalid_credentials", 400)
    validate_password(new, user)
    with transaction.atomic():
        user.set_password(new)
        user.save(update_fields=["password"])
        revoke_all_tokens(user)
        _, access, refresh = AuthToken.issue(user)
        record(user, "auth.password_changed", user)
    return access, refresh


@transaction.atomic
def create_user(
    actor: User,
    *,
    username: str,
    password: str,
    role: str,
    full_name: str = "",
    phone: str = "",
    address: str = "",
    is_org: bool = False,
    contact_person: str = "",
    note: str = "",
    avatar_url: str = "",
) -> User:
    if not can_manage_account_of(actor, role):
        raise DomainError("You may not create this kind of account.", "forbidden", 403)
    validate_password(password)
    user = User(
        username=username, role=role, full_name=full_name, phone=phone, address=address, is_org=is_org,
        contact_person=contact_person, note=note, avatar_url=avatar_url,
    )  # fmt: skip
    user.set_password(password)
    user.save()
    record(actor, "user.created", user, role=role)
    return user


def _active_owner_count() -> int:
    return User.objects.filter(role=Role.OWNER, is_active=True).count()


@transaction.atomic
def delete_user(actor: User, target: User) -> str:
    """Remove an account. A person who never produced history is deleted for good; anyone referenced by tasks,
    messages or audit rows (PROTECT) is deactivated and signed out instead. Returns "deleted" or "deactivated"."""
    target = User.objects.select_for_update().get(pk=target.pk)
    if not can_manage_account_of(actor, target.role):
        raise DomainError("You may not delete this account.", "forbidden", 403)
    if target.pk == actor.pk:
        raise DomainError("You cannot delete yourself.", "self_modification", 403)
    if target.role == Role.OWNER and target.is_active and _active_owner_count() <= 1:
        raise DomainError("The last active owner cannot be deleted.", "last_owner", 409)
    revoke_all_tokens(target)
    try:
        with transaction.atomic():
            target_id = target.pk
            target.delete()
        record(actor, "user.deleted", None, user=target_id)
        return "deleted"
    except ProtectedError:
        target = User.objects.get(pk=target.pk)
        target.is_active = False
        target.save(update_fields=["is_active"])
        record(actor, "user.deactivated", target, reason="delete_requested")
        return "deactivated"


@transaction.atomic
def update_user(actor: User, target: User, changes: dict) -> User:
    """Apply role/activation/profile changes with the invariants that keep the company administrable."""
    target = User.objects.select_for_update().get(pk=target.pk)
    new_role = changes.get("role", target.role)
    new_active = changes.get("is_active", target.is_active)

    if not (can_manage_account_of(actor, target.role) and can_manage_account_of(actor, new_role)):
        raise DomainError("You may not modify this account.", "forbidden", 403)
    if target.pk == actor.pk and (new_role != target.role or new_active is False):
        raise DomainError("You cannot change your own role or deactivate yourself.", "self_modification", 403)
    losing_owner = target.role == Role.OWNER and target.is_active and (new_role != Role.OWNER or not new_active)
    if losing_owner and _active_owner_count() <= 1:
        raise DomainError("The last active owner cannot be demoted or deactivated.", "last_owner", 409)

    role_changed, active_changed = new_role != target.role, new_active != target.is_active
    for field, value in changes.items():
        setattr(target, field, value)
    target.save()
    if role_changed:
        record(actor, "user.role_changed", target, new_role=new_role)
    if active_changed:
        record(actor, "user.activated" if new_active else "user.deactivated", target)
        if not new_active:
            revoke_all_tokens(target)
    if role_changed:
        revoke_all_tokens(target)  # a role change must not outlive old sessions' assumptions
    return target
