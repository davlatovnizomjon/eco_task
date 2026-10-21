from django.db.models import Q

from apps.accounts.models import User

from .models import Notification


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
        recipients = task_audience(conversation.task)
    else:
        recipients = set(
            Membership.objects.filter(conversation=conversation, left_at__isnull=True).values_list("user_id", flat=True)
        )
    active = User.objects.filter(pk__in=recipients, is_active=True).values_list("pk", flat=True)
    name = message.sender.full_name or message.sender.username if message.sender else "Someone"
    notify(active, "chat.message", f"New message from {name}", conversation=conversation, exclude=message.sender_id)


def unread_filter() -> Q:
    return Q(read_at__isnull=True)
