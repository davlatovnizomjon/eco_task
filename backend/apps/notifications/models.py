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
