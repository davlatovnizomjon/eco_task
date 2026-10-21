"""Who may see which tasks. One place, used by REST, WebSocket rooms, files and reports."""

from django.db.models import Q

from apps.core.policies import Role, is_staff_role

from .models import Task


def visible_tasks(user):
    """Queryset of tasks `user` may read. Unknown or foreign ids simply are not in it (-> 404)."""
    if not getattr(user, "is_authenticated", False) or not user.is_active:
        return Task.objects.none()
    if is_staff_role(user):
        return Task.objects.all()
    if user.role == Role.CLIENT:
        return Task.objects.filter(Q(client=user) | Q(creator=user))
    return Task.objects.filter(assignments__worker=user, assignments__unassigned_at__isnull=True).distinct()


def can_view_task(user, task_id) -> bool:
    return visible_tasks(user).filter(pk=task_id).exists()
