from django.conf import settings
from django.db import models


class Notification(models.Model):
    """Inbox entry. Never stores message bodies: it points at the conversation or task instead."""

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications")
    kind = models.CharField(max_length=32)
    title = models.CharField(max_length=200)
    task = models.ForeignKey("tasks.Task", null=True, blank=True, on_delete=models.CASCADE, related_name="+")
    conversation = models.ForeignKey(
        "chat.Conversation", null=True, blank=True, on_delete=models.CASCADE, related_name="+"
    )
    service_request = models.ForeignKey(
        "client_requests.ServiceRequest", null=True, blank=True, on_delete=models.CASCADE, related_name="+"
    )
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at", "-id"]
        indexes = [models.Index(fields=["user", "read_at", "-created_at"])]

    def __str__(self) -> str:
        return f"{self.kind} for {self.user_id}"


class DeviceToken(models.Model):
    """A push (FCM) registration token of one installed app. A token belongs to exactly one user at a time."""

    PLATFORMS = [("ios", "ios"), ("android", "android"), ("web", "web")]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="device_tokens")
    token = models.CharField(max_length=512, unique=True)
    platform = models.CharField(max_length=8, choices=PLATFORMS)
    language = models.CharField(max_length=8, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["user"], name="notificatio_user_id_5c1d0e_idx")]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(platform__in=["ios", "android", "web"]), name="device_platform_valid"
            )
        ]

    def __str__(self) -> str:
        return f"{self.platform} token of {self.user_id}"
