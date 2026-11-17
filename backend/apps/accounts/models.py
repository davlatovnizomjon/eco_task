import hashlib
import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.core.validators import URLValidator
from django.db import models
from django.utils import timezone

from apps.core.policies import Role

AVATAR_URL_VALIDATOR = URLValidator(schemes=["http", "https"])


class User(AbstractUser):
    """Company user. `role` is the only authority switch and is never writable by the user themselves."""

    role = models.CharField(max_length=16, choices=[(r.value, r.value) for r in Role], default=Role.WORKER.value)
    phone = models.CharField(max_length=32, blank=True)
    address = models.CharField(max_length=300, blank=True)
    contact_person = models.CharField(max_length=150, blank=True, help_text="Responsible person of an organization.")
    note = models.CharField(max_length=300, blank=True)
    is_org = models.BooleanField(default=False, help_text="A client that is an organization, not a private person.")
    full_name = models.CharField(max_length=150, blank=True)
    avatar_url = models.URLField(max_length=500, blank=True, validators=[AVATAR_URL_VALIDATOR])
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
    """A session: a short-lived opaque access token plus a long-lived refresh token.

    Only SHA-256 digests are stored, so a database leak does not leak sessions. Refreshing rotates both values in
    place, which makes the previous refresh token useless the moment a new pair is issued.
    """

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="auth_tokens")
    key_hash = models.CharField(max_length=64, unique=True)
    refresh_hash = models.CharField(max_length=64, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    refresh_expires_at = models.DateTimeField(null=True, blank=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    last_used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=["user", "revoked_at"])]

    def __str__(self) -> str:
        return f"token#{self.pk} user={self.user_id}"

    @staticmethod
    def _new_pair() -> tuple[str, str, dict]:
        access, refresh = secrets.token_urlsafe(32), secrets.token_urlsafe(48)
        now = timezone.now()
        fields = {
            "key_hash": hash_token(access),
            "refresh_hash": hash_token(refresh),
            "expires_at": now + timedelta(minutes=settings.API_ACCESS_TOKEN_MINUTES),
            "refresh_expires_at": now + timedelta(days=settings.API_REFRESH_TOKEN_DAYS),
        }
        return access, refresh, fields

    @classmethod
    def issue(cls, user) -> tuple["AuthToken", str, str]:
        """Create a session and return (row, access, refresh). The raw values are shown to the client exactly once."""
        access, refresh, fields = cls._new_pair()
        return cls.objects.create(user=user, **fields), access, refresh

    def rotate(self) -> tuple[str, str]:
        """Replace both tokens of this session and return the new raw (access, refresh)."""
        access, refresh, fields = self._new_pair()
        for name, value in fields.items():
            setattr(self, name, value)
        self.save(update_fields=list(fields))
        return access, refresh

    @property
    def is_valid(self) -> bool:
        return self.revoked_at is None and self.expires_at > timezone.now()

    @property
    def can_refresh(self) -> bool:
        expires = self.refresh_expires_at
        return self.revoked_at is None and expires is not None and expires > timezone.now()
