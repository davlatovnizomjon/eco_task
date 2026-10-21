from drf_spectacular.utils import extend_schema
from rest_framework import generics

from apps.core.permissions import has_cap
from apps.core.policies import Cap

from .models import AuditLog
from .serializers import AuditLogSerializer


@extend_schema(tags=["audit"])
class AuditLogList(generics.ListAPIView):
    """Read-only; no create/update/delete route exists."""

    permission_classes = [has_cap(Cap.VIEW_AUDIT)]
    serializer_class = AuditLogSerializer
    queryset = AuditLog.objects.select_related("actor")
    filterset_fields = ["action"]

    def get_queryset(self):
        qs = super().get_queryset()
        action = self.request.query_params.get("action")
        return qs.filter(action=action) if action else qs
