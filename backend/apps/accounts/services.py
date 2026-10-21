"""User lifecycle rules. Views stay thin; every rule here is covered by tests."""

import logging

from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.utils import timezone

from apps.audit.services import record
from apps.core.errors import DomainError
from apps.core.policies import Role

from .models import AuthToken, User

logger = logging.getLogger(__name__)


def login(username: str, password: str, ip: str = "") -> tuple[User, str]:
    user = authenticate(username=username, password=password)
    if user is None or not user.is_active:
        # Never log the password; the username is enough to spot brute-force patterns.
        record(None, "auth.login_failed", username=username[:150], ip=ip)
        raise DomainError("Invalid username or password.", "invalid_credentials", 401)
    _, raw = AuthToken.issue(user)
    record(user, "auth.login", user)
    return user, raw


def revoke_all_tokens(user: User) -> None:
    AuthToken.objects.filter(user=user, revoked_at__isnull=True).update(revoked_at=timezone.now())


def change_password(user: User, old: str, new: str) -> str:
    """Change the password, revoke every session, and return a fresh token for the current device."""
    if not user.check_password(old):
        raise DomainError("Current password is incorrect.", "invalid_credentials", 400)
    validate_password(new, user)
    with transaction.atomic():
        user.set_password(new)
        user.save(update_fields=["password"])
        revoke_all_tokens(user)
        _, raw = AuthToken.issue(user)
        record(user, "auth.password_changed", user)
    return raw


@transaction.atomic
def create_user(actor: User, *, username: str, password: str, role: str, full_name: str = "", phone: str = "") -> User:
    validate_password(password)
    user = User(username=username, role=role, full_name=full_name, phone=phone)
    user.set_password(password)
    user.save()
    record(actor, "user.created", user, role=role)
    return user


def _active_owner_count() -> int:
    return User.objects.filter(role=Role.OWNER, is_active=True).count()


@transaction.atomic
def update_user(actor: User, target: User, changes: dict) -> User:
    """Apply role/activation/profile changes with the invariants that keep the company administrable."""
    target = User.objects.select_for_update().get(pk=target.pk)
    new_role = changes.get("role", target.role)
    new_active = changes.get("is_active", target.is_active)

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
