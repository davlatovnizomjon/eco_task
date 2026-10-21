"""Chat rules shared by REST and WebSocket paths. Access is decided here and nowhere else."""

import logging

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.db import IntegrityError, transaction
from django.db.models import Count, F, Max, OuterRef, Q, Subquery
from django.db.models.functions import Coalesce
from django.utils import timezone

from apps.accounts.models import User
from apps.audit.services import record
from apps.core.errors import DomainError
from apps.core.policies import Cap, can, is_staff_role
from apps.tasks.access import can_view_task, visible_tasks

from .models import Conversation, Kind, Membership, Message

logger = logging.getLogger(__name__)


def group_name(conversation_id) -> str:
    return f"chat.{conversation_id}"


def user_group(user_id) -> str:
    return f"user.{user_id}"


def can_access(user: User, conversation: Conversation) -> bool:
    if not user.is_authenticated or not user.is_active:
        return False
    if conversation.kind == Kind.TASK:
        return can_view_task(user, conversation.task_id)  # live check: unassigned workers lose access at once
    return Membership.objects.filter(conversation=conversation, user=user, left_at__isnull=True).exists()


def accessible_conversations(user: User):
    member_of = Q(memberships__user=user, memberships__left_at__isnull=True, kind__in=[Kind.DIRECT, Kind.GROUP])
    task_chats = Q(kind=Kind.TASK, task__in=visible_tasks(user).values("pk"))
    return Conversation.objects.filter(member_of | task_chats).distinct()


def get_conversation_for(user: User, pk) -> Conversation:
    """Unknown id and forbidden id are indistinguishable (both 404)."""
    conversation = Conversation.objects.filter(pk=pk).first()
    if conversation is None or not can_access(user, conversation):
        raise DomainError("Conversation not found.", "not_found", 404)
    return conversation


def _can_direct(a: User, b: User) -> bool:
    return a.pk != b.pk and a.is_active and b.is_active and (is_staff_role(a) or is_staff_role(b))


@transaction.atomic
def open_direct(actor: User, other: User) -> Conversation:
    if not _can_direct(actor, other):
        raise DomainError("You may not message this user.", "forbidden", 403)
    low, high = sorted([actor.pk, other.pk])
    conversation, created = Conversation.objects.get_or_create(
        direct_key=f"{low}:{high}", defaults={"kind": Kind.DIRECT, "created_by": actor}
    )
    if created:
        Membership.objects.bulk_create([Membership(conversation=conversation, user=u) for u in (actor, other)])
    return conversation


@transaction.atomic
def create_group(actor: User, title: str, members: list[User]) -> Conversation:
    if not can(actor, Cap.MANAGE_CONVERSATIONS):
        raise DomainError("You may not create group conversations.", "forbidden", 403)
    conversation = Conversation.objects.create(kind=Kind.GROUP, title=title, created_by=actor)
    for user in {actor, *[m for m in members if m.is_active]}:
        Membership.objects.create(conversation=conversation, user=user)
    record(actor, "chat.group_created", conversation)
    return conversation


@transaction.atomic
def open_task_chat(actor: User, task_id) -> Conversation:
    if not can_view_task(actor, task_id):
        raise DomainError("Task not found.", "not_found", 404)
    conversation, _ = Conversation.objects.get_or_create(task_id=task_id, defaults={"kind": Kind.TASK, "created_by": actor})
    return conversation


@transaction.atomic
def add_members(actor: User, conversation: Conversation, users: list[User]) -> None:
    if conversation.kind != Kind.GROUP:
        raise DomainError("Members can only be managed in group conversations.", "invalid_operation", 400)
    if not can(actor, Cap.MANAGE_CONVERSATIONS) or not can_access(actor, conversation):
        raise DomainError("You may not manage this conversation.", "forbidden", 403)
    for user in users:
        if not user.is_active:
            continue
        member, created = Membership.objects.get_or_create(conversation=conversation, user=user)
        if not created and member.left_at:
            member.left_at = None
            member.save(update_fields=["left_at"])
    record(actor, "chat.members_added", conversation, users=[u.pk for u in users])


@transaction.atomic
def remove_member(actor: User, conversation: Conversation, user: User) -> None:
    if conversation.kind != Kind.GROUP:
        raise DomainError("Members can only be managed in group conversations.", "invalid_operation", 400)
    if user.pk != actor.pk and not (can(actor, Cap.MANAGE_CONVERSATIONS) and can_access(actor, conversation)):
        raise DomainError("You may not manage this conversation.", "forbidden", 403)
    updated = Membership.objects.filter(conversation=conversation, user=user, left_at__isnull=True).update(
        left_at=timezone.now()
    )
    if not updated:
        raise DomainError("Not a member.", "not_found", 404)
    record(actor, "chat.member_removed", conversation, user=user.pk)
    transaction.on_commit(lambda: revoke_access(conversation.pk, user.pk))


def revoke_access(conversation_id, user_id) -> None:
    """Tell live sockets of `user_id` to drop `conversation_id`. Failure is logged; the DB check still blocks sends."""
    layer = get_channel_layer()
    try:
        async_to_sync(layer.group_send)(
            user_group(user_id), {"type": "chat.revoke", "conversation": str(conversation_id)}
        )
    except Exception:
        logger.exception("could not push revocation to user %s", user_id)


def revoke_task_chat(task_id, user_ids) -> None:
    conversation_id = Conversation.objects.filter(task_id=task_id).values_list("pk", flat=True).first()
    if conversation_id:
        for user_id in user_ids:
            transaction.on_commit(lambda uid=user_id: revoke_access(conversation_id, uid))


def send_message(user: User, conversation: Conversation, body: str, client_msg_id: str = "") -> tuple[Message, bool]:
    """Persist first, broadcast second. Returns (message, created); a repeated client_msg_id returns the original."""
    body = body.strip()
    if not body or len(body) > settings.CHAT_MAX_MESSAGE_CHARS:
        raise DomainError("Message must be 1-%d characters." % settings.CHAT_MAX_MESSAGE_CHARS, "invalid_message", 400)
    if not can_access(user, conversation):
        raise DomainError("Conversation not found.", "not_found", 404)
    try:
        with transaction.atomic():
            message = Message.objects.create(
                conversation=conversation, sender=user, body=body, client_msg_id=client_msg_id
            )
    except IntegrityError:
        existing = Message.objects.filter(conversation=conversation, sender=user, client_msg_id=client_msg_id).first()
        if existing is None:
            raise
        return existing, False
    ensure_membership(conversation, user)
    Membership.objects.filter(conversation=conversation, user=user, last_read_message_id__lt=message.pk).update(
        last_read_message_id=message.pk
    )
    broadcast_message(message)
    from apps.notifications.services import notify_new_message

    notify_new_message(message)
    return message, True


def ensure_membership(conversation: Conversation, user: User) -> Membership:
    return Membership.objects.get_or_create(conversation=conversation, user=user)[0]


def serialize_message(message: Message) -> dict:
    return {
        "id": message.pk,
        "conversation": str(message.conversation_id),
        "sender": message.sender_id,
        "body": message.body,
        "client_msg_id": message.client_msg_id,
        "created_at": message.created_at.isoformat(),
    }


def broadcast_message(message: Message) -> None:
    """Best-effort fan-out. A Redis outage must never lose or fail an already-persisted message."""
    try:
        async_to_sync(get_channel_layer().group_send)(
            group_name(message.conversation_id), {"type": "chat.message", "message": serialize_message(message)}
        )
    except Exception:
        logger.exception("broadcast failed for message %s; it remains stored and in history", message.pk)


def mark_read(user: User, conversation: Conversation, message_id: int) -> int:
    if not can_access(user, conversation):
        raise DomainError("Conversation not found.", "not_found", 404)
    newest = Message.objects.filter(conversation=conversation, pk__lte=message_id).aggregate(m=Max("pk"))["m"] or 0
    membership = ensure_membership(conversation, user)
    updated = Membership.objects.filter(pk=membership.pk, last_read_message_id__lt=newest).update(
        last_read_message_id=newest
    )
    if updated:  # tell other participants about the read receipt (best effort)
        try:
            async_to_sync(get_channel_layer().group_send)(
                group_name(conversation.pk),
                {"type": "chat.read", "user": user.pk, "message_id": newest, "conversation": str(conversation.pk)},
            )
        except Exception:
            logger.exception("read receipt broadcast failed")
    return newest


def unread_counts(user: User, conversation_ids: list) -> dict:
    """Messages from others newer than the user's read marker, in one query for all conversations."""
    marker = Membership.objects.filter(conversation=OuterRef("pk"), user=user).values("last_read_message_id")[:1]
    rows = (
        Conversation.objects.filter(pk__in=conversation_ids)
        .annotate(marker=Coalesce(Subquery(marker), 0))
        .annotate(unread=Count("messages", filter=Q(messages__id__gt=F("marker")) & ~Q(messages__sender=user)))
        .values_list("pk", "unread")
    )
    return dict(rows)
