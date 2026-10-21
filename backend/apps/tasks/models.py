import uuid

from django.conf import settings
from django.db import models
from django.db.models import F, Q


class Status(models.TextChoices):
    OPEN = "OPEN"
    IN_PROGRESS = "IN_PROGRESS"
    REVIEW = "REVIEW"  # worker submitted; waiting for a manager when approval is enabled
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELED = "CANCELED"


class Priority(models.TextChoices):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"


class Task(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    creator = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="created_tasks")
    client = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name="client_tasks"
    )
    project = models.ForeignKey(
        "projects.Project", null=True, blank=True, on_delete=models.PROTECT, related_name="tasks"
    )
    workers = models.ManyToManyField(
        settings.AUTH_USER_MODEL, through="TaskAssignment", through_fields=("task", "worker"), related_name="tasks"
    )
    status = models.CharField(max_length=16, choices=Status.choices, default=Status.OPEN, db_index=True)
    priority = models.CharField(max_length=8, choices=Priority.choices, default=Priority.MEDIUM)
    start_date = models.DateField(null=True, blank=True)
    due_date = models.DateField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    # Financial: what was agreed with the client. NOT revenue; payments live in apps.finance.
    agreed_value = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    failure_reason = models.TextField(blank=True)
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    version = models.PositiveIntegerField(default=1)  # optimistic concurrency token
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at", "-id"]
        indexes = [
            models.Index(fields=["status", "due_date"]),
            models.Index(fields=["client", "status"]),
            models.Index(fields=["project", "status"]),
        ]
        constraints = [
            models.CheckConstraint(
                condition=Q(agreed_value__isnull=True) | Q(agreed_value__gte=0), name="task_value_nonneg"
            ),
            models.CheckConstraint(
                condition=Q(due_date__isnull=True) | Q(start_date__isnull=True) | Q(due_date__gte=F("start_date")),
                name="task_due_after_start",
            ),
            models.CheckConstraint(condition=Q(status__in=[s.value for s in Status]), name="task_status_valid"),
            models.CheckConstraint(
                condition=~Q(status="FAILED") | ~Q(failure_reason=""), name="task_failed_needs_reason"
            ),
            models.CheckConstraint(
                condition=(Q(status="COMPLETED") & Q(completed_at__isnull=False))
                | (~Q(status="COMPLETED") & Q(completed_at__isnull=True)),
                name="task_completed_at_matches_status",
            ),
        ]

    def __str__(self) -> str:
        return self.title


class TaskAssignment(models.Model):
    """Worker <-> task link with history: unassigning closes the row instead of deleting it."""

    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name="assignments")
    worker = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="assignments")
    assigned_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    assigned_at = models.DateTimeField(auto_now_add=True)
    unassigned_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["task", "worker"], condition=Q(unassigned_at__isnull=True), name="one_active_assignment"
            )
        ]
        indexes = [models.Index(fields=["worker", "unassigned_at"])]

    def __str__(self) -> str:
        return f"{self.worker_id}->{self.task_id}"


class TaskHistory(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name="history")
    from_status = models.CharField(max_length=16, blank=True)
    to_status = models.CharField(max_length=16)
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    reason = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at", "id"]

    def __str__(self) -> str:
        return f"{self.task_id}: {self.from_status}->{self.to_status}"


class TaskComment(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name="comments")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    body = models.TextField(max_length=4000)
    is_internal = models.BooleanField(default=False)  # hidden from clients
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at", "id"]

    def __str__(self) -> str:
        return f"comment#{self.pk} on {self.task_id}"
