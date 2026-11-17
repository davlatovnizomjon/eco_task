from django.contrib import admin

from apps.core.admin_site import PolicyAdmin, ReadOnlyInline

from .models import Task, TaskAssignment, TaskComment, TaskHistory


class TaskAssignmentInline(ReadOnlyInline):
    model = TaskAssignment
    fk_name = "task"


class TaskHistoryInline(ReadOnlyInline):
    model = TaskHistory


class TaskCommentInline(ReadOnlyInline):
    model = TaskComment


@admin.register(Task)
class TaskAdmin(PolicyAdmin):
    """Status, approval and history are owned by the task service, so they are read-only here."""

    allow_add = False  # a task needs a creator, an audit trail and a conversation: create it through the API
    list_display = ("title", "status", "priority", "client", "project", "due_date", "created_at")
    list_filter = ("status", "priority")
    search_fields = ("title", "client__username", "client__full_name", "project__name")
    date_hierarchy = "created_at"
    autocomplete_fields = ("client", "project")
    fields = (
        "title",
        "description",
        "priority",
        "client",
        "project",
        "start_date",
        "due_date",
        "agreed_value",
        "currency",
        "client_name",
        "client_is_org",
        "address",
        "remind_at",
        "status",
        "failure_reason",
        "creator",
        "approved_by",
        "approved_at",
        "completed_at",
        "version",
        "created_at",
        "updated_at",
    )
    readonly_fields = (
        "status",
        "failure_reason",
        "creator",
        "approved_by",
        "approved_at",
        "completed_at",
        "version",
        "created_at",
        "updated_at",
    )
    inlines = (TaskAssignmentInline, TaskHistoryInline, TaskCommentInline)

    def save_model(self, request, obj, form, change) -> None:
        obj.version += 1  # keep the optimistic-concurrency token honest for API clients holding an older copy
        super().save_model(request, obj, form, change)
