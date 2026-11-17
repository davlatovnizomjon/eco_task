import re

from django.core.exceptions import ValidationError
from django.db import models

PHONE_RE = re.compile(r"^\+?[\d\s()-]{7,20}$")
TELEGRAM_RE = re.compile(r"^@?[A-Za-z][A-Za-z0-9_]{4,31}$")


def validate_phone(value: str) -> None:
    """Digits with an optional leading `+`, spaces, dashes and brackets (`+998 71 200 00 00`)."""
    if not PHONE_RE.match(value) or sum(c.isdigit() for c in value) < 7:
        raise ValidationError("Enter a phone number such as +998 71 200 00 00.")


def validate_telegram(value: str) -> None:
    """A Telegram username, with or without the leading `@`."""
    if not TELEGRAM_RE.match(value):
        raise ValidationError("Enter a Telegram username such as @eco_tasks_bot.")


class SupportContact(models.Model):
    """How people reach the dispatcher. Exactly one row (pk=1), edited in the admin."""

    phone = models.CharField(max_length=24, validators=[validate_phone])
    telegram = models.CharField(max_length=33, validators=[validate_telegram])
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.CheckConstraint(condition=models.Q(pk=1), name="support_contact_single_row")]

    def save(self, *args, **kwargs) -> None:
        self.pk = 1
        kwargs.pop("force_insert", None)  # `create()` on the existing row updates it instead of failing
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        return f"{self.phone} / {self.telegram}"
