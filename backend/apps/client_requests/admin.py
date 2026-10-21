from django.contrib import admin

from apps.core.admin_site import PolicyAdmin, ReadOnlyInline
from apps.core.policies import Cap

from .models import RequestMessage, ServiceRequest


class RequestMessageInline(ReadOnlyInline):
    model = RequestMessage


@admin.register(ServiceRequest)
class ServiceRequestAdmin(PolicyAdmin):
    """Only scheduling and the assignee can be edited; the status moves forward through the API."""

    cap = Cap.MANAGE_REQUESTS
    allow_add = False
    list_display = ("id", "title", "kind", "status", "client", "assignee", "date", "created_at")
    list_filter = ("status", "kind")
    search_fields = ("title", "address", "client__username", "client__full_name")
    date_hierarchy = "created_at"
    autocomplete_fields = ("assignee",)
    fields = (
        "title",
        "detail",
        "kind",
        "address",
        "client",
        "status",
        "assignee",
        "date",
        "slot",
        "created_at",
        "updated_at",
    )
    readonly_fields = ("title", "detail", "kind", "address", "client", "status", "created_at", "updated_at")
    inlines = (RequestMessageInline,)
