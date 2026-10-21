"""Pure transition table: which moves exist, and who may perform each. No database access here."""

from django.conf import settings

from apps.core.policies import Cap, Role, can

from .models import Status

S = Status
# (from, to) -> actor kinds allowed. "assignee" = active assigned worker, "approver" = APPROVE_TASK holder,
# "client_creator" = the client who owns the task.
RULES: dict[tuple[str, str], set[str]] = {
    (S.OPEN, S.IN_PROGRESS): {"assignee", "approver"},
    (S.IN_PROGRESS, S.REVIEW): {"assignee", "approver"},
    (S.IN_PROGRESS, S.COMPLETED): {"approver", "assignee_if_no_approval"},
    (S.REVIEW, S.COMPLETED): {"approver"},
    (S.REVIEW, S.IN_PROGRESS): {"approver"},  # returned for rework
    (S.OPEN, S.FAILED): {"approver"},
    (S.IN_PROGRESS, S.FAILED): {"approver"},
    (S.REVIEW, S.FAILED): {"approver"},
    (S.OPEN, S.CANCELED): {"approver", "client_creator"},
    (S.IN_PROGRESS, S.CANCELED): {"approver"},
    (S.REVIEW, S.CANCELED): {"approver"},
}
REASON_REQUIRED = {(S.REVIEW, S.IN_PROGRESS), (S.OPEN, S.FAILED), (S.IN_PROGRESS, S.FAILED), (S.REVIEW, S.FAILED)}


def actor_kinds(user, task, is_assignee: bool) -> set[str]:
    kinds: set[str] = set()
    if is_assignee and user.role == Role.WORKER:
        kinds.add("assignee")
        if not settings.TASK_COMPLETION_REQUIRES_APPROVAL:
            kinds.add("assignee_if_no_approval")
    if can(user, Cap.APPROVE_TASK):
        kinds.add("approver")
    if user.role == Role.CLIENT and task.client_id == user.pk:
        kinds.add("client_creator")
    return kinds


def allowed(user, task, is_assignee: bool, to_status: str) -> bool:
    needed = RULES.get((task.status, to_status))
    return bool(needed and needed & actor_kinds(user, task, is_assignee))
