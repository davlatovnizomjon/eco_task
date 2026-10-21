from rest_framework import serializers

from apps.accounts.serializers import UserBriefSerializer

from .models import Conversation, Kind, Message


class MessageSerializer(serializers.ModelSerializer):
    sender = UserBriefSerializer(read_only=True)

    class Meta:
        model = Message
        fields = ["id", "conversation", "sender", "body", "client_msg_id", "created_at"]
        read_only_fields = fields


class MessageInputSerializer(serializers.Serializer):
    body = serializers.CharField(max_length=4000)
    client_msg_id = serializers.CharField(max_length=64, required=False, allow_blank=True)


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


def conversation_payload(conversation: Conversation, unread: int, last_message: Message | None, members) -> dict:
    return {
        "id": str(conversation.pk),
        "kind": conversation.kind,
        "title": conversation.title,
        "task": str(conversation.task_id) if conversation.task_id else None,
        "unread_count": unread,
        "last_message": MessageSerializer(last_message).data if last_message else None,
        "members": members,
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


class MessagePageSerializer(serializers.Serializer):
    results = MessageSerializer(many=True)
    has_more = serializers.BooleanField()


class ReadResultSerializer(serializers.Serializer):
    last_read_message_id = serializers.IntegerField()
