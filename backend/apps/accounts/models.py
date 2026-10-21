import hashlib
import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

from apps.core.policies import Role


class User(AbstractUser):
    """Company user. `role` is the only authority switch and is never writable by the user themselves."""

    role = models.CharField(max_length=16, choices=[(r.value, r.value) for r in Role], default=Role.WORKER.value)
    phone = models.CharField(max_length=32, blank=True)
    full_name = models.CharField(max_length=150, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    first_name = None  # replaced by full_name
    last_name = None

    class Meta:
        constraints = [
            models.CheckConstraint(condition=models.Q(role__in=[r.value for r in Role]), name="user_role_valid"),
        ]
        indexes = [models.Index(fields=["role", "is_active"])]

    def __str__(self) -> str:
        return f"{self.username} ({self.role})"


def hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()


class AuthToken(models.Model):
    """Opaque bearer token. Only the SHA-256 digest is stored, so a database leak does not leak sessions."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="auth_tokens")
    key_hash = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=["user", "revoked_at"])]

    def __str__(self) -> str:
        return f"token#{self.pk} user={self.user_id}"

    @classmethod
    def issue(cls, user) -> tuple["AuthToken", str]:
        """Create a token and return (row, raw value). The raw value is shown to the client exactly once."""
        raw = secrets.token_urlsafe(32)
        lifetime = timedelta(hours=settings.API_TOKEN_LIFETIME_HOURS)
        row = cls.objects.create(user=user, key_hash=hash_token(raw), expires_at=timezone.now() + lifetime)
        return row, raw

    @property
    def is_valid(self) -> bool:
        return self.revoked_at is None and self.expires_at > timezone.now()
