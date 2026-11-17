from rest_framework import serializers

from apps.accounts.serializers import UserBriefSerializer
from apps.files.serializers import AttachmentSerializer

from .models import Conversation, Kind, Message


def reaction_summary(message: Message) -> list[dict]:
    """`[{emoji, user_ids}]` in first-use order; clients derive the count and their own "mine" flag from it."""
    grouped: dict[str, list[int]] = {}
    for r in message.reactions.all():
        grouped.setdefault(r.emoji, []).append(r.user_id)
    return [{"emoji": emoji, "user_ids": ids} for emoji, ids in grouped.items()]


def reply_summary(parent: Message | None) -> dict | None:
    """The quoted message as a small card: who wrote it and a one-line preview (no body of deleted messages)."""
    if parent is None:
        return None
    deleted = parent.deleted_at is not None
    sender = parent.sender
    return {
        "id": parent.pk,
        "sender_name": (sender.full_name or sender.username) if sender else "",
        "body": "" if deleted else parent.body[:120],
        "deleted": deleted,
        "attachment_kind": parent.attachment.kind if parent.attachment and not deleted else None,
    }


class MessageSerializer(serializers.ModelSerializer):
    sender = UserBriefSerializer(read_only=True)
    body = serializers.SerializerMethodField()
    deleted = serializers.SerializerMethodField()
    reactions = serializers.SerializerMethodField()
    attachment = serializers.SerializerMethodField()
    reply_to = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = [
            "id", "conversation", "sender", "body", "client_msg_id", "created_at", "edited_at", "deleted", "reactions",
            "attachment", "reply_to",
        ]  # fmt: skip
        read_only_fields = fields

    def get_body(self, message) -> str:
        return "" if message.deleted_at else message.body

    def get_deleted(self, message) -> bool:
        return message.deleted_at is not None

    def get_reactions(self, message) -> list:
        return reaction_summary(message)

    def get_attachment(self, message) -> dict | None:
        if message.deleted_at or message.attachment is None:
            return None
        return AttachmentSerializer(message.attachment).data

    def get_reply_to(self, message) -> dict | None:
        return reply_summary(message.reply_to)


class MessageInputSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=4000, required=False, allow_blank=True)
    client_msg_id = serializers.CharField(max_length=64, required=False, allow_blank=True)
    reply_to = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    attachment_id = serializers.IntegerField(min_value=1, required=False, allow_null=True)

    def validate(self, attrs):
        if not attrs.get("body", "").strip() and not attrs.get("attachment_id"):
            raise serializers.ValidationError({"body": "A message needs text or an attachment."})
        return attrs


class MessageEditSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=4000)


class ReactionSerializer(serializers.Serializer):
    emoji = serializers.CharField(max_length=16)


class PinSerializer(serializers.Serializer):
    message_id = serializers.IntegerField(min_value=1)


class ConversationUpdateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200, required=False)
    avatar_id = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    muted = serializers.BooleanField(required=False)


class ConversationCreateSerializer(serializers.Serializer):
    kind = serializers.ChoiceField(choices=Kind.choices)
    user = serializers.IntegerField(required=False)
    task = serializers.UUIDField(required=False)
    title = serializers.CharField(max_length=200, required=False)
    member_ids = serializers.ListField(child=serializers.IntegerField(), required=False, max_length=100)

    def validate(self, attrs):
        need = {"DIRECT": "user", "TASK": "task", "GROUP": "title"}[attrs["kind"]]
        if need not in attrs:
            raise serializers.ValidationError({need: "This field is required for this kind."})
        return attrs


class MembersSerializer(serializers.Serializer):
    user_ids = serializers.ListField(child=serializers.IntegerField(), max_length=100)


class ReadSerializer(serializers.Serializer):
    message_id = serializers.IntegerField(min_value=1)


def conversation_payload(
    conversation: Conversation, unread: int, last_message: Message | None, members, muted: bool = False
) -> dict:
    pinned = conversation.pinned_message
    return {
        "id": str(conversation.pk),
        "kind": conversation.kind,
        "title": conversation.title,
        "task": str(conversation.task_id) if conversation.task_id else None,
        "unread_count": unread,
        "last_message": MessageSerializer(last_message).data if last_message else None,
        "members": members,
        "muted": muted,
        "avatar": AttachmentSerializer(conversation.avatar).data if conversation.avatar else None,
        "pinned_message": MessageSerializer(pinned).data if pinned else None,
    }


class ConversationSerializer(serializers.Serializer):
    """Documentation shape of `conversation_payload` (the view builds the dict by hand)."""

    id = serializers.UUIDField()
    kind = serializers.ChoiceField(choices=Kind.choices)
    title = serializers.CharField()
    task = serializers.UUIDField(allow_null=True)
    unread_count = serializers.IntegerField()
    last_message = MessageSerializer(allow_null=True)
    members = serializers.ListField(child=serializers.DictField(), help_text="Empty for TASK conversations.")
    muted = serializers.BooleanField()
    avatar = AttachmentSerializer(allow_null=True)
    pinned_message = MessageSerializer(allow_null=True)


class MessagePageSerializer(serializers.Serializer):
    results = MessageSerializer(many=True)
    has_more = serializers.BooleanField()


class ReadResultSerializer(serializers.Serializer):
    last_read_message_id = serializers.IntegerField()
