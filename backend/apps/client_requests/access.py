"""Who may see which requests. Unknown and foreign ids are both simply absent (-> 404)."""

from apps.core.policies import Role, is_staff_role

from .models import ServiceRequest


def visible_requests(user):
    if not getattr(user, "is_authenticated", False) or not user.is_active:
        return ServiceRequest.objects.none()
    if is_staff_role(user):
        return ServiceRequest.objects.all()
    if user.role == Role.CLIENT:
        return ServiceRequest.objects.filter(client=user)
    return ServiceRequest.objects.none()
