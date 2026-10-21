from django.contrib import admin

from apps.core.admin_site import ReadOnlyAdmin
from apps.core.policies import Cap

from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(ReadOnlyAdmin):
    cap = Cap.VIEW_AUDIT
    list_display = ("created_at", "action", "actor", "target_type", "target_id")
    list_filter = ("action", "target_type")
    search_fields = ("action", "target_id", "actor__username")
    date_hierarchy = "created_at"
    ordering = ("-created_at", "-id")
