from rest_framework.permissions import BasePermission

from .policies import Cap, can


class HasCap(BasePermission):
    """Subclass-free factory: `permission_classes = [has_cap(Cap.X)]`."""

    cap: Cap

    def has_permission(self, request, view) -> bool:
        return can(request.user, self.cap)


def has_cap(cap: Cap) -> type[HasCap]:
    return type(f"Has_{cap.name}", (HasCap,), {"cap": cap})
