from django.db.models import Q

from apps.accounts.models import User

from .models import DeviceToken, Notification
from .push import queue_push


def notify(users, kind: str, title: str, *, task=None, conversation=None, service_request=None, exclude=None) -> None:
    ids = {u.pk if hasattr(u, "pk") else u for u in users} - {getattr(exclude, "pk", exclude)}
    Notification.objects.bulk_create(
        [
            Notification(
                user_id=uid,
                kind=kind,
                title=title[:200],
                task=task,
                conversation=conversation,
                service_request=service_request,
            )
            for uid in ids
        ]
    )
    queue_push(
        ids,
        title,
        {
            "kind": kind,
            **({"task_id": str(task.pk)} if task else {}),
            **({"conversation_id": str(conversation.pk)} if conversation else {}),
            **({"request_id": str(service_request.pk)} if service_request else {}),
        },
    )


def register_device(user, token: str, platform: str, language: str) -> None:
    """Remember a device's push token for `user`; a token that moved to another account is re-assigned."""
    DeviceToken.objects.update_or_create(
        token=token, defaults={"user": user, "platform": platform, "language": language}
    )


def unregister_device(user, token: str) -> None:
    """Forget one of the caller's own tokens (sign-out); someone else's token is left alone."""
    DeviceToken.objects.filter(user=user, token=token).delete()


def task_audience(task) -> set[int]:
    """People directly involved in a task: creator, client and active assignees."""
    ids = {task.creator_id}
    if task.client_id:
        ids.add(task.client_id)
    ids.update(task.assignments.filter(unassigned_at__isnull=True).values_list("worker_id", flat=True))
    return ids


def notify_new_message(message) -> None:
    from apps.chat.models import Kind, Membership

    conversation = message.conversation
    if conversation.kind == Kind.TASK:
        muted = Membership.objects.filter(conversation=conversation, muted=True).values_list("user_id", flat=True)
        recipients = task_audience(conversation.task) - set(muted)
    else:
        recipients = set(
            Membership.objects.filter(conversation=conversation, left_at__isnull=True, muted=False).values_list(
                "user_id", flat=True
            )
        )
    active = User.objects.filter(pk__in=recipients, is_active=True).values_list("pk", flat=True)
    name = message.sender.full_name or message.sender.username if message.sender else "Someone"
    notify(active, "chat.message", f"New message from {name}", conversation=conversation, exclude=message.sender_id)


def unread_filter() -> Q:
    return Q(read_at__isnull=True)
