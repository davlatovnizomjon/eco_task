import uuid

from django.conf import settings
from django.db import models
from django.db.models import Q


class Kind(models.TextChoices):
    DIRECT = "DIRECT"
    GROUP = "GROUP"
    TASK = "TASK"


class Conversation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    kind = models.CharField(max_length=8, choices=Kind.choices)
    title = models.CharField(max_length=200, blank=True)
    task = models.OneToOneField("tasks.Task", null=True, blank=True, on_delete=models.CASCADE, related_name="conversation")
    direct_key = models.CharField(max_length=40, null=True, blank=True, unique=True)  # "lowId:highId" for DIRECT
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=(Q(kind="TASK", task__isnull=False) | ~Q(kind="TASK", task__isnull=True))
                & (Q(kind="DIRECT", direct_key__isnull=False) | ~Q(kind="DIRECT", direct_key__isnull=True)),
                name="conversation_kind_fields_consistent",
            )
        ]

    def __str__(self) -> str:
        return f"{self.kind} {self.pk}"


class Membership(models.Model):
    """Who belongs to a DIRECT/GROUP conversation, plus the read marker. TASK conversations derive access
    from task visibility; their rows exist only to hold the per-user read marker."""

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="memberships")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="chat_memberships")
    joined_at = models.DateTimeField(auto_now_add=True)
    left_at = models.DateTimeField(null=True, blank=True)
    last_read_message_id = models.BigIntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["conversation", "user"], name="one_membership_per_user_and_conversation")
        ]
        indexes = [models.Index(fields=["user", "left_at"])]

    def __str__(self) -> str:
        return f"{self.user_id} in {self.conversation_id}"


class Message(models.Model):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    body = models.TextField(max_length=4000, blank=True)
    # Client-generated id; retrying the same send (flaky network) can never create a duplicate row.
    client_msg_id = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["id"]
        indexes = [models.Index(fields=["conversation", "id"])]
        constraints = [
            models.UniqueConstraint(
                fields=["conversation", "sender", "client_msg_id"],
                condition=~Q(client_msg_id=""),
                name="message_idempotency",
            )
        ]

    def __str__(self) -> str:
        return f"message#{self.pk}"
