import re

from django.core.exceptions import ValidationError
from django.core.validators import URLValidator
from django.db import models

STORE_URL_VALIDATOR = URLValidator(schemes=["http", "https"])
VERSION_RE = re.compile(r"^\d{1,4}(\.\d{1,4}){1,3}$")


def validate_version(value: str) -> None:
    """Dotted numeric versions only (`1.2` or `1.2.3`), so the app can compare them part by part."""
    if not VERSION_RE.match(value):
        raise ValidationError("Use a dotted numeric version such as 1.2.3.")


class Platform(models.TextChoices):
    ANDROID = "android"
    IOS = "ios"


class AppRelease(models.Model):
    """The newest published build of the mobile app for one platform; the app compares its own version with it."""

    platform = models.CharField(max_length=16, choices=Platform.choices, unique=True)
    latest_version = models.CharField(max_length=20, validators=[validate_version])
    force_update = models.BooleanField(default=False, help_text="Blocks the app until the user updates.")
    is_maintenance = models.BooleanField(
        default=False, help_text="Technical work: the app shows the maintenance screen instead of its content."
    )
    store_url = models.URLField(max_length=500, blank=True, validators=[STORE_URL_VALIDATOR])
    title = models.CharField(
        max_length=120, blank=True, help_text="Headline of the update dialog. Empty: the app uses its own text."
    )
    subtitle = models.CharField(
        max_length=300, blank=True, help_text="Text under the headline (what is new). Empty: the app uses its own text."
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.CheckConstraint(condition=models.Q(platform__in=Platform.values), name="release_platform_valid"),
        ]

    def __str__(self) -> str:
        return f"{self.platform} {self.latest_version}"
