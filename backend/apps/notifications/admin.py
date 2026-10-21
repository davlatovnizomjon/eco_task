from django.contrib import admin

from apps.core.admin_site import ReadOnlyAdmin

from .models import Notification


@admin.register(Notification)
class NotificationAdmin(ReadOnlyAdmin):
    list_display = ("created_at", "user", "kind", "title", "read_at")
    list_filter = ("kind",)
    search_fields = ("user__username", "title")
    date_hierarchy = "created_at"
