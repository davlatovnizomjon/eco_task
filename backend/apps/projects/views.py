from django.db.models import Q
from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import viewsets
from rest_framework.exceptions import PermissionDenied

from apps.audit.services import record
from apps.core.policies import Cap, Role, can, is_staff_role

from .models import Project
from .serializers import ProjectSerializer


@extend_schema_view(
    list=extend_schema(tags=["projects"]),
    retrieve=extend_schema(tags=["projects"]),
    create=extend_schema(tags=["projects"]),
    partial_update=extend_schema(tags=["projects"]),
)
class ProjectViewSet(viewsets.ModelViewSet):
    """Staff see all; clients see their own; workers see projects of tasks they are assigned to."""

    serializer_class = ProjectSerializer
    queryset = Project.objects.none()  # real queryset is per-user (get_queryset); this one only feeds OpenAPI
    http_method_names = ["get", "post", "patch", "head", "options"]  # deactivate via is_active; no DELETE

    def get_queryset(self):
        user = self.request.user
        qs = Project.objects.select_related("client")
        if is_staff_role(user):
            return qs
        if user.role == Role.CLIENT:
            return qs.filter(client=user)
        return qs.filter(
            Q(tasks__assignments__worker=user, tasks__assignments__unassigned_at__isnull=True), is_active=True
        ).distinct()

    def _require_manage(self):
        if not can(self.request.user, Cap.MANAGE_PROJECTS):
            raise PermissionDenied("You may not manage projects.")

    def perform_create(self, serializer):
        self._require_manage()
        project = serializer.save(created_by=self.request.user)
        record(self.request.user, "project.created", project)

    def perform_update(self, serializer):
        self._require_manage()
        project = serializer.save()
        record(self.request.user, "project.updated", project, fields=sorted(serializer.validated_data))
