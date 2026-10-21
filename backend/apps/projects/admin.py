from django.contrib import admin

from apps.core.admin_site import PolicyAdmin
from apps.core.policies import Cap

from .models import Project


@admin.register(Project)
class ProjectAdmin(PolicyAdmin):
    cap = Cap.MANAGE_PROJECTS
    list_display = ("name", "client", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("name", "client__username", "client__full_name")
    autocomplete_fields = ("client",)
    readonly_fields = ("created_by", "created_at")

    def save_model(self, request, obj, form, change) -> None:
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
