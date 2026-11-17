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
    task = models.OneToOneField(
        "tasks.Task", null=True, blank=True, on_delete=models.CASCADE, related_name="conversation"
    )
    direct_key = models.CharField(max_length=40, null=True, blank=True, unique=True)  # "lowId:highId" for DIRECT
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    # The message shown in the banner at the top of the room (one per conversation); cleared when it is deleted.
    avatar = models.ForeignKey("files.Attachment", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    pinned_message = models.ForeignKey(
        "chat.Message", null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
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
    muted = models.BooleanField(default=False)  # no inbox notifications for new messages

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
    edited_at = models.DateTimeField(null=True, blank=True)
    reply_to = models.ForeignKey("self", null=True, blank=True, on_delete=models.SET_NULL, related_name="+")
    attachment = models.OneToOneField(
        "files.Attachment", null=True, blank=True, on_delete=models.SET_NULL, related_name="message"
    )  # photo, document, voice note or video circle
    # Soft delete: the row stays so ids, read markers and replies keep working; the body is wiped.
    deleted_at = models.DateTimeField(null=True, blank=True)

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


class MessageReaction(models.Model):
    """One emoji reaction of one user on one message; reacting again replaces the previous emoji."""

    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name="reactions")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    emoji = models.CharField(max_length=16)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["message", "user"], name="one_reaction_per_user_and_message")]

    def __str__(self) -> str:
        return f"{self.emoji} by {self.user_id} on {self.message_id}"


class Call(models.Model):
    """A voice or video call in a DIRECT or GROUP conversation. Media flows peer to peer (WebRTC); the server only
    keeps the call's state and relays signalling between participants."""

    class CallKind(models.TextChoices):
        AUDIO = "AUDIO"
        VIDEO = "VIDEO"

    class CallStatus(models.TextChoices):
        RINGING = "RINGING"
        ACTIVE = "ACTIVE"
        ENDED = "ENDED"
        DECLINED = "DECLINED"
        MISSED = "MISSED"
        CANCELED = "CANCELED"

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="calls")
    caller = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    kind = models.CharField(max_length=5, choices=CallKind.choices)
    status = models.CharField(max_length=10, choices=CallStatus.choices, default=CallStatus.RINGING, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    answered_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-id"]
        indexes = [models.Index(fields=["conversation", "-id"])]
        constraints = [
            models.UniqueConstraint(
                fields=["conversation"],
                condition=Q(status__in=["RINGING", "ACTIVE"]),
                name="one_live_call_per_conversation",
            )
        ]

    def __str__(self) -> str:
        return f"{self.kind} call {self.pk} ({self.status})"


class CallParticipant(models.Model):
    """One invited person of a call and what they did with the invitation."""

    class State(models.TextChoices):
        INVITED = "INVITED"
        JOINED = "JOINED"
        DECLINED = "DECLINED"
        LEFT = "LEFT"
        MISSED = "MISSED"

    call = models.ForeignKey(Call, on_delete=models.CASCADE, related_name="participants")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="+")
    state = models.CharField(max_length=10, choices=State.choices, default=State.INVITED)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["call", "user"], name="one_participant_row_per_call")]

    def __str__(self) -> str:
        return f"{self.user_id} in call {self.call_id}: {self.state}"
