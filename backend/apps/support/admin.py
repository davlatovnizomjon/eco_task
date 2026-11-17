from django.contrib import admin

from apps.core.admin_site import PolicyAdmin

from .models import SupportContact


@admin.register(SupportContact)
class SupportContactAdmin(PolicyAdmin):
    list_display = ("phone", "telegram", "updated_at")

    def has_add_permission(self, request) -> bool:
        return super().has_add_permission(request) and not SupportContact.objects.exists()
