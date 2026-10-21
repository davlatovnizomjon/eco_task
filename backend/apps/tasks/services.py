"""Task business rules. Every mutation is one transaction that also writes history/audit rows."""

from django.db import transaction
from django.utils import timezone

from apps.accounts.models import User
from apps.audit.services import record
from apps.core.errors import DomainError
from apps.core.policies import Cap, Role, can
from apps.notifications.services import notify, task_audience
from apps.projects.models import Project

from . import transitions
from .models import Status, Task, TaskAssignment, TaskComment, TaskHistory

EDITABLE_BY_STAFF = {"title", "description", "priority", "start_date", "due_date", "client", "project", "agreed_value"}


def _check_project_client(project, client):
    if project and project.client_id and client and project.client_id != client.pk:
        raise DomainError("The project belongs to a different client.", "project_client_mismatch", 400)


@transaction.atomic
def create_task(actor: User, data: dict) -> Task:
    if not can(actor, Cap.CREATE_TASK):
        raise DomainError("You may not create tasks.", "forbidden", 403)
    data = dict(data)
    worker_ids = data.pop("worker_ids", [])
    if actor.role == Role.CLIENT:
        # Clients can only create for themselves, inside their own projects, and cannot price or staff the task.
        project = data.get("project")
        if project and project.client_id != actor.pk:
            raise DomainError("Unknown project.", "not_found", 404)
        if worker_ids or data.get("agreed_value") is not None:
            raise DomainError("Clients cannot assign workers or set prices.", "forbidden", 403)
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
    return task


@transaction.atomic
def update_task(actor: User, task_id, changes: dict, version: int | None) -> Task:
    task = Task.objects.select_for_update().get(pk=task_id)
    if not can(actor, Cap.ASSIGN_TASK):
        raise DomainError("You may not edit tasks.", "forbidden", 403)
    if "agreed_value" in changes and not can(actor, Cap.MANAGE_FINANCE):
        raise DomainError("You may not change the agreed value.", "forbidden", 403)
    _check_version(task, version)
    if task.status in (Status.COMPLETED, Status.FAILED, Status.CANCELED):
        raise DomainError("Closed tasks cannot be edited.", "task_closed", 409)
    for field, value in changes.items():
        if field in EDITABLE_BY_STAFF:
            setattr(task, field, value)
    _check_project_client(task.project, task.client)
    task.version += 1
    task.save()
    record(actor, "task.updated", task, fields=sorted(changes))
    return task


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


def add_comment(actor: User, task: Task, body: str, internal: bool = False) -> TaskComment:
    # Clients can never write internal notes (they could not read them back).
    return TaskComment.objects.create(
        task=task, author=actor, body=body, is_internal=internal and actor.role != Role.CLIENT
    )


def project_for(actor: User, project_id) -> Project | None:
    return Project.objects.filter(pk=project_id).first() if project_id else None
