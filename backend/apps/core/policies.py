"""Central role/capability policy. Views and services ask `can()`; they never compare roles ad hoc."""

from enum import StrEnum


class Role(StrEnum):
    OWNER = "OWNER"
    ASSISTANT = "ASSISTANT"
    WORKER = "WORKER"
    CLIENT = "CLIENT"


class Cap(StrEnum):
    MANAGE_USERS = "manage_users"
    CREATE_TASK = "create_task"
    ASSIGN_TASK = "assign_task"
    VIEW_ALL_TASKS = "view_all_tasks"
    APPROVE_TASK = "approve_task"
    MANAGE_PROJECTS = "manage_projects"
    VIEW_REPORTS = "view_reports"
    VIEW_FINANCE = "view_finance"
    MANAGE_FINANCE = "manage_finance"
    VIEW_AUDIT = "view_audit"
    MANAGE_CONVERSATIONS = "manage_conversations"
    CREATE_REQUEST = "create_request"
    MANAGE_REQUESTS = "manage_requests"


# Single source of truth. Assistants deliberately get no finance or audit capability:
# the brief forbids implicit financial/administrative access for them.
ROLE_CAPS: dict[Role, frozenset[Cap]] = {
    Role.OWNER: frozenset(Cap),
    Role.ASSISTANT: frozenset(
        {
            Cap.CREATE_TASK,
            Cap.ASSIGN_TASK,
            Cap.VIEW_ALL_TASKS,
            Cap.APPROVE_TASK,
            Cap.MANAGE_PROJECTS,
            Cap.VIEW_REPORTS,
            Cap.MANAGE_CONVERSATIONS,
            Cap.MANAGE_REQUESTS,
        }
    ),
    Role.WORKER: frozenset(),
    Role.CLIENT: frozenset(
        {Cap.CREATE_TASK, Cap.CREATE_REQUEST}
    ),  # scoped to the client's own account in the task service
}


def can(user, cap: Cap) -> bool:
    """True when `user` is an active, authenticated user whose role grants `cap`."""
    if not getattr(user, "is_authenticated", False) or not user.is_active:
        return False
    try:
        return cap in ROLE_CAPS[Role(user.role)]
    except ValueError:
        return False


def is_staff_role(user) -> bool:
    """OWNER or ASSISTANT: the company-side people who see beyond their own assignments."""
    return getattr(user, "role", None) in (Role.OWNER, Role.ASSISTANT)
