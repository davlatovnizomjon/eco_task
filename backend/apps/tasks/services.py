"""Task business rules. Every mutation is one transaction that also writes history/audit rows."""

from django.db import transaction
from django.db.models import Q
from django.utils import timezone

from apps.accounts.models import User
from apps.audit.services import record
from apps.core.errors import DomainError
from apps.core.policies import Cap, Role, can
from apps.notifications.services import notify, task_audience
from apps.projects.models import Project

from . import transitions
from .models import Status, Task, TaskAssignment, TaskComment, TaskHistory

EDITABLE_BY_STAFF = {
    "title", "description", "priority", "start_date", "due_date", "client", "project", "agreed_value",
    "currency", "client_name", "client_is_org", "address", "remind_at",
}  # fmt: skip

# What a client may change on their own order while nobody has started it.
EDITABLE_BY_CLIENT = {
    "title", "description", "start_date", "due_date", "agreed_value", "currency", "address", "remind_at",
}  # fmt: skip


def _owns_open_order(actor: User, task: Task) -> bool:
    """A client may edit or delete an order they created until work on it starts."""
    return actor.role == Role.CLIENT and task.creator_id == actor.pk and task.status == Status.OPEN


def _check_project_client(project, client):
    if project and project.client_id and client and project.client_id != client.pk:
        raise DomainError("The project belongs to a different client.", "project_client_mismatch", 400)


@transaction.atomic
def create_task(actor: User, data: dict) -> Task:
    if not can(actor, Cap.CREATE_TASK):
        raise DomainError("You may not create tasks.", "forbidden", 403)
    data = dict(data)
    worker_ids = data.pop("worker_ids", [])
    attachment_ids = data.pop("attachment_ids", [])
    if actor.role == Role.CLIENT:
        # Clients can only create for themselves, inside their own projects, and cannot staff the task; the price
        # they give is their own budget for the order.
        project = data.get("project")
        if project and project.client_id != actor.pk:
            raise DomainError("Unknown project.", "not_found", 404)
        if worker_ids:
            raise DomainError("Clients cannot assign workers.", "forbidden", 403)
        data["client"] = actor
    elif data.get("agreed_value") is not None and not can(actor, Cap.MANAGE_FINANCE):
        raise DomainError("You may not set the agreed value.", "forbidden", 403)
    if data.get("project") is not None and not data["project"].is_active:
        raise DomainError("The project is not active.", "project_inactive", 400)
    if data.get("client") is None and data.get("project") is not None and data["project"].client_id:
        data["client"] = data["project"].client
    _check_project_client(data.get("project"), data.get("client"))
    task = Task.objects.create(creator=actor, **data)
    TaskHistory.objects.create(task=task, from_status="", to_status=Status.OPEN, actor=actor)
    record(actor, "task.created", task)
    if worker_ids:
        set_assignees(actor, task, worker_ids)
    if attachment_ids:
        set_attachments(actor, task, attachment_ids)
    return task


@transaction.atomic
def update_task(actor: User, task_id, changes: dict, version: int | None) -> Task:
    task = Task.objects.select_for_update().get(pk=task_id)
    own_order = _owns_open_order(actor, task)
    if not can(actor, Cap.ASSIGN_TASK) and not own_order:
        raise DomainError("You may not edit tasks.", "forbidden", 403)
    if "agreed_value" in changes and not can(actor, Cap.MANAGE_FINANCE) and not own_order:
        raise DomainError("You may not change the agreed value.", "forbidden", 403)
    if own_order and not can(actor, Cap.ASSIGN_TASK) and set(changes) - EDITABLE_BY_CLIENT - {"attachment_ids"}:
        raise DomainError("You may not change these fields.", "forbidden", 403)
    _check_version(task, version)
    if task.status in (Status.COMPLETED, Status.FAILED, Status.CANCELED):
        raise DomainError("Closed tasks cannot be edited.", "task_closed", 409)
    changes = dict(changes)
    attachment_ids = changes.pop("attachment_ids", None)
    for field, value in changes.items():
        if field in EDITABLE_BY_STAFF:
            setattr(task, field, value)
    _check_project_client(task.project, task.client)
    task.version += 1
    task.save()
    if attachment_ids is not None:
        set_attachments(actor, task, attachment_ids)
    record(actor, "task.updated", task, fields=sorted(changes))
    return task


@transaction.atomic
def set_attachments(actor: User, task: Task, ids: list[int]) -> None:
    """Make the task's files equal `ids`: files already on the task stay, the caller's own unattached uploads are
    adopted, anything left out is deleted. At most 10 images and 5 documents."""
    from apps.files.models import Attachment, Kind
    from apps.files.services import MAX_TASK_DOCS, MAX_TASK_IMAGES, remove_file

    wanted = list(dict.fromkeys(ids))
    mine = Attachment.objects.filter(pk__in=wanted).filter(Q(task=task) | Q(owner=actor, task__isnull=True))
    found = {a.pk: a for a in mine}
    if set(found) != set(wanted):
        raise DomainError("Unknown attachment.", "invalid_attachment", 400)
    images = sum(a.kind == Kind.IMAGE for a in found.values())
    docs = sum(a.kind == Kind.DOCUMENT for a in found.values())
    if (
        images > MAX_TASK_IMAGES
        or docs > MAX_TASK_DOCS
        or any(a.kind in (Kind.AUDIO, Kind.VIDEO) for a in found.values())
    ):
        raise DomainError("Too many or unsupported files for a task.", "too_many_files", 400)
    for attachment in task.attachments.exclude(pk__in=wanted):
        remove_file(attachment)
    Attachment.objects.filter(pk__in=[a.pk for a in found.values() if a.task_id is None]).update(task=task)
    record(actor, "task.files_changed", task, count=len(wanted))


def _check_version(task: Task, version: int | None) -> None:
    if version is not None and version != task.version:
        raise DomainError("The task was changed by someone else. Reload and retry.", "version_conflict", 409)


@transaction.atomic
def set_assignees(actor: User, task: Task, worker_ids: list[int]) -> Task:
    """Make the active worker set equal to `worker_ids`; removed workers keep a closed assignment row."""
    if not can(actor, Cap.ASSIGN_TASK):
        raise DomainError("You may not assign workers.", "forbidden", 403)
    task = Task.objects.select_for_update().get(pk=task.pk)
    if task.status in (Status.COMPLETED, Status.FAILED, Status.CANCELED):
        raise DomainError("Closed tasks cannot be reassigned.", "task_closed", 409)
    wanted = set(worker_ids)
    workers = {u.pk: u for u in User.objects.filter(pk__in=wanted, role=Role.WORKER, is_active=True)}
    if set(workers) != wanted:
        raise DomainError("Every assignee must be an active worker.", "invalid_assignee", 400)
    active = {a.worker_id: a for a in task.assignments.filter(unassigned_at__isnull=True)}
    now = timezone.now()
    for worker_id in wanted - set(active):
        TaskAssignment.objects.create(task=task, worker=workers[worker_id], assigned_by=actor)
    for worker_id in set(active) - wanted:
        TaskAssignment.objects.filter(pk=active[worker_id].pk).update(unassigned_at=now)
    if wanted != set(active):
        notify(wanted - set(active), "task.assigned", f"You were assigned: {task.title}", task=task, exclude=actor)
        from apps.chat.services import revoke_task_chat

        revoke_task_chat(task.pk, set(active) - wanted)
        record(
            actor,
            "task.assignees_changed",
            task,
            added=sorted(wanted - set(active)),
            removed=sorted(set(active) - wanted),
        )
    return task


@transaction.atomic
def transition(actor: User, task_id, to_status: str, reason: str = "", version: int | None = None) -> Task:
    task = Task.objects.select_for_update().get(pk=task_id)  # serialises concurrent status changes
    _check_version(task, version)
    key = (task.status, to_status)
    is_assignee = task.assignments.filter(worker=actor, unassigned_at__isnull=True).exists()
    if key not in transitions.RULES:
        raise DomainError(f"Cannot move a task from {task.status} to {to_status}.", "invalid_transition", 409)
    if not transitions.allowed(actor, task, is_assignee, to_status):
        raise DomainError("You may not perform this status change.", "forbidden", 403)
    reason = reason.strip()
    if key in transitions.REASON_REQUIRED and not reason:
        raise DomainError("A reason is required for this change.", "reason_required", 400)
    previous = task.status
    task.status = to_status
    now = timezone.now()
    task.completed_at = now if to_status == Status.COMPLETED else None
    task.failure_reason = reason if to_status == Status.FAILED else ""
    if to_status == Status.COMPLETED and can(actor, Cap.APPROVE_TASK):
        task.approved_by, task.approved_at = actor, now
    task.version += 1
    task.save()
    TaskHistory.objects.create(task=task, from_status=previous, to_status=to_status, actor=actor, reason=reason)
    record(actor, "task.status_changed", task, from_status=previous, to_status=to_status)
    notify(task_audience(task), "task.status", f"{task.title}: {previous} -> {to_status}", task=task, exclude=actor)
    return task


@transaction.atomic
def delete_task(actor: User, task_id) -> None:
    """Remove a task for good: any task for the owner and assistant (`DELETE_TASK`), only their own not-yet-started
    order for a client. Assignments, history, comments and the task chat go with it."""
    task = Task.objects.select_for_update().get(pk=task_id)
    if not can(actor, Cap.DELETE_TASK) and not _owns_open_order(actor, task):
        raise DomainError("You may not delete tasks.", "forbidden", 403)
    record(actor, "task.deleted", task, title=task.title, status=task.status)
    from apps.files.services import remove_file

    for attachment in task.attachments.all():
        remove_file(attachment)
    task.delete()


@transaction.atomic
def delete_comment(actor: User, task: Task, comment_id) -> None:
    """Staff may remove any comment; everyone else only their own."""
    comment = task.comments.filter(pk=comment_id).first()
    if comment is None or (comment.is_internal and actor.role == Role.CLIENT):
        raise DomainError("Comment not found.", "not_found", 404)
    if comment.author_id != actor.pk and not can(actor, Cap.ASSIGN_TASK):
        raise DomainError("You may only delete your own comments.", "forbidden", 403)
    record(actor, "task.comment_deleted", task, comment=comment.pk)
    comment.delete()


def add_comment(actor: User, task: Task, body: str, internal: bool = False) -> TaskComment:
    # Clients can never write internal notes (they could not read them back).
    return TaskComment.objects.create(
        task=task, author=actor, body=body, is_internal=internal and actor.role != Role.CLIENT
    )


def project_for(actor: User, project_id) -> Project | None:
    return Project.objects.filter(pk=project_id).first() if project_id else None
