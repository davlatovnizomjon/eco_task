from django.db.models import Max, Q
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.serializers import UserBriefSerializer
from apps.core.errors import DomainError
from apps.core.policies import Role, is_staff_role

from . import services
from .models import Kind, Membership, Message
from .serializers import (
    ConversationCreateSerializer,
    ConversationSerializer,
    ConversationUpdateSerializer,
    MembersSerializer,
    MessageEditSerializer,
    MessageInputSerializer,
    MessagePageSerializer,
    MessageSerializer,
    PinSerializer,
    ReactionSerializer,
    ReadResultSerializer,
    ReadSerializer,
    conversation_payload,
)


def _members(conversation, viewer) -> list[dict]:
    """Participants with their read markers. Clients only ever see staff names, never other clients."""
    rows = Membership.objects.filter(conversation=conversation, left_at__isnull=True).select_related("user")
    out = []
    for m in rows:
        if viewer.role == Role.CLIENT and m.user.role == Role.CLIENT and m.user_id != viewer.pk:
            continue
        out.append({**UserBriefSerializer(m.user).data, "last_read_message_id": m.last_read_message_id})
    return out


def _payload(conversation, viewer, unread=None):
    last = conversation.messages.order_by("-id").select_related("sender").first()
    if unread is None:
        unread = services.unread_counts(viewer, [conversation.pk]).get(conversation.pk, 0)
    members = _members(conversation, viewer) if conversation.kind != Kind.TASK else []
    muted = Membership.objects.filter(conversation=conversation, user=viewer, muted=True).exists()
    return conversation_payload(conversation, unread, last, members, muted)


class ConversationList(APIView):
    @extend_schema(tags=["chat"], responses=ConversationSerializer(many=True))
    def get(self, request):
        conversations = list(services.accessible_conversations(request.user).order_by("-created_at")[:200])
        unread = services.unread_counts(request.user, [c.pk for c in conversations])
        latest = dict(
            Message.objects.filter(conversation__in=conversations).values_list("conversation").annotate(m=Max("id"))
        )
        conversations.sort(key=lambda c: latest.get(c.pk, 0), reverse=True)
        return Response([_payload(c, request.user, unread.get(c.pk, 0)) for c in conversations])

    @extend_schema(tags=["chat"], request=ConversationCreateSerializer, responses={201: ConversationSerializer})
    def post(self, request):
        data = ConversationCreateSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        v, user = data.validated_data, request.user
        if v["kind"] == Kind.DIRECT:
            other = User.objects.filter(pk=v["user"], is_active=True).first()
            if other is None:
                raise DomainError("User not found.", "not_found", 404)
            conversation = services.open_direct(user, other)
        elif v["kind"] == Kind.TASK:
            conversation = services.open_task_chat(user, v["task"])
        else:
            members = list(User.objects.filter(pk__in=v.get("member_ids", []), is_active=True))
            conversation = services.create_group(user, v["title"], members)
        return Response(_payload(conversation, user), status=status.HTTP_201_CREATED)


class ConversationDetail(APIView):
    @extend_schema(tags=["chat"], responses=ConversationSerializer)
    def get(self, request, pk):
        return Response(_payload(services.get_conversation_for(request.user, pk), request.user))

    @extend_schema(tags=["chat"], request=ConversationUpdateSerializer, responses=ConversationSerializer)
    def patch(self, request, pk):
        conversation = services.get_conversation_for(request.user, pk)
        data = ConversationUpdateSerializer(data=request.data, partial=True)
        data.is_valid(raise_exception=True)
        v = data.validated_data
        services.update_conversation(
            request.user,
            conversation,
            title=v.get("title"),
            muted=v.get("muted"),
            avatar_id=v["avatar_id"] if "avatar_id" in v else services._UNSET,
        )
        return Response(_payload(conversation, request.user))


class ConversationPin(APIView):
    @extend_schema(tags=["chat"], request=PinSerializer, responses=ConversationSerializer)
    def put(self, request, pk):
        conversation = services.get_conversation_for(request.user, pk)
        data = PinSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        services.set_pin(request.user, conversation, data.validated_data["message_id"])
        return Response(_payload(conversation, request.user))

    @extend_schema(tags=["chat"], responses=ConversationSerializer)
    def delete(self, request, pk):
        conversation = services.get_conversation_for(request.user, pk)
        services.set_pin(request.user, conversation, None)
        return Response(_payload(conversation, request.user))


class ConversationMembers(APIView):
    @extend_schema(tags=["chat"], request=MembersSerializer, responses=ConversationSerializer)
    def post(self, request, pk):
        conversation = services.get_conversation_for(request.user, pk)
        data = MembersSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        users = list(User.objects.filter(pk__in=data.validated_data["user_ids"], is_active=True))
        services.add_members(request.user, conversation, users)
        return Response(_payload(conversation, request.user))


class ConversationMember(APIView):
    @extend_schema(tags=["chat"], responses={204: None})
    def delete(self, request, pk, user_id):
        conversation = services.get_conversation_for(request.user, pk)
        target = User.objects.filter(pk=user_id).first()
        if target is None:
            raise DomainError("Not a member.", "not_found", 404)
        services.remove_member(request.user, conversation, target)
        return Response(status=status.HTTP_204_NO_CONTENT)


class MessageList(APIView):
    """History is cursor-paginated newest-first: `?before=<message id>&limit=<=100`."""

    @extend_schema(
        tags=["chat"],
        parameters=[
            OpenApiParameter("before", int, description="Return messages with id below this."),
            OpenApiParameter("limit", int),
        ],
        responses=MessagePageSerializer,
    )
    def get(self, request, pk):
        conversation = services.get_conversation_for(request.user, pk)
        try:
            limit = max(1, min(int(request.query_params.get("limit", 30)), 100))
            before = int(request.query_params.get("before", 0))
        except ValueError:
            raise DomainError("limit and before must be integers.", "invalid_query", 400) from None
        qs = (
            Message.objects.filter(conversation=conversation)
            .select_related("sender", "attachment", "reply_to", "reply_to__sender")
            .prefetch_related("reactions")
            .order_by("-id")
        )
        if before:
            qs = qs.filter(pk__lt=before)
        rows = list(qs[: limit + 1])
        return Response({"results": MessageSerializer(rows[:limit], many=True).data, "has_more": len(rows) > limit})

    @extend_schema(
        tags=["chat"], request=MessageInputSerializer, responses={200: MessageSerializer, 201: MessageSerializer}
    )
    def post(self, request, pk):
        """REST fallback used while the socket reconnects; same rules and idempotency as the socket path."""
        conversation = services.get_conversation_for(request.user, pk)
        data = MessageInputSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        v = data.validated_data
        message, created = services.send_message(
            request.user,
            conversation,
            v.get("body", ""),
            v.get("client_msg_id", ""),
            v.get("reply_to"),
            v.get("attachment_id"),
        )
        return Response(
            MessageSerializer(message).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )


class MessageDetail(APIView):
    @extend_schema(tags=["chat"], request=MessageEditSerializer, responses=MessageSerializer)
    def patch(self, request, pk, message_id):
        conversation = services.get_conversation_for(request.user, pk)
        data = MessageEditSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        message = services.edit_message(request.user, conversation, message_id, data.validated_data["body"])
        return Response(MessageSerializer(message).data)

    @extend_schema(tags=["chat"], responses=MessageSerializer)
    def delete(self, request, pk, message_id):
        conversation = services.get_conversation_for(request.user, pk)
        return Response(MessageSerializer(services.delete_message(request.user, conversation, message_id)).data)


class MessageReactionView(APIView):
    @extend_schema(tags=["chat"], request=ReactionSerializer, responses=MessageSerializer)
    def put(self, request, pk, message_id):
        conversation = services.get_conversation_for(request.user, pk)
        data = ReactionSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        message = services.set_reaction(request.user, conversation, message_id, data.validated_data["emoji"])
        return Response(MessageSerializer(message).data)

    @extend_schema(tags=["chat"], responses=MessageSerializer)
    def delete(self, request, pk, message_id):
        conversation = services.get_conversation_for(request.user, pk)
        return Response(MessageSerializer(services.set_reaction(request.user, conversation, message_id, None)).data)


class ConversationRead(APIView):
    @extend_schema(tags=["chat"], request=ReadSerializer, responses=ReadResultSerializer)
    def post(self, request, pk):
        conversation = services.get_conversation_for(request.user, pk)
        data = ReadSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        return Response(
            {"last_read_message_id": services.mark_read(request.user, conversation, data.validated_data["message_id"])}
        )


class ContactList(APIView):
    """People the caller may start a direct chat with (staff may write to anyone, others only to staff)."""

    @extend_schema(
        tags=["chat"],
        parameters=[OpenApiParameter("q", str, description="Search in username and full name.")],
        responses=UserBriefSerializer(many=True),
    )
    def get(self, request):
        qs = User.objects.filter(is_active=True).exclude(pk=request.user.pk).order_by("full_name", "username")
        if not is_staff_role(request.user):
            qs = qs.filter(role__in=[Role.OWNER, Role.ASSISTANT])
        q = request.query_params.get("q", "").strip()[:100]
        if q:
            qs = qs.filter(Q(username__icontains=q) | Q(full_name__icontains=q))
        return Response(UserBriefSerializer(qs[:100], many=True).data)
