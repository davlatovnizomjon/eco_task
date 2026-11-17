from django.contrib import admin

from apps.core.admin_site import PolicyAdmin

from .models import AppRelease


@admin.register(AppRelease)
class AppReleaseAdmin(PolicyAdmin):
    list_display = ("platform", "latest_version", "force_update", "is_maintenance", "title", "updated_at")
    list_editable = ("latest_version", "force_update", "is_maintenance")
