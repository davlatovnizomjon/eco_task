from django.conf import settings
from django.db import models


class Kind(models.TextChoices):
    DELIVERY = "DELIVERY"
    PLANTING = "PLANTING"
    CARE = "CARE"


class Status(models.TextChoices):
    ACCEPTED = "ACCEPTED"
    PLANNED = "PLANNED"
    IN_PROGRESS = "IN_PROGRESS"
    DONE = "DONE"


# Requests only move forward through these steps.
STATUS_ORDER = [Status.ACCEPTED, Status.PLANNED, Status.IN_PROGRESS, Status.DONE]


class ServiceRequest(models.Model):
    """A client's ask for a service (delivery, planting, care). Handled by staff, followed by the client."""

    client = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="service_requests")
    title = models.CharField(max_length=200)
    detail = models.TextField(blank=True)
    kind = models.CharField(max_length=16, choices=Kind.choices, default=Kind.DELIVERY)
    address = models.CharField(max_length=300)
    date = models.DateField(null=True, blank=True)  # wished date, later the planned one
    slot = models.CharField(max_length=20, blank=True)  # wished time window, e.g. "09:00–12:00"
    status = models.CharField(max_length=16, choices=Status.choices, default=Status.ACCEPTED, db_index=True)
    assignee = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="assigned_requests"
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at", "-id"]
        indexes = [models.Index(fields=["client", "status"])]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(status__in=[s.value for s in Status]), name="request_status_valid"
            ),
            models.CheckConstraint(condition=models.Q(kind__in=[k.value for k in Kind]), name="request_kind_valid"),
        ]

    def __str__(self) -> str:
        return f"{self.code} {self.title}"

    @property
    def code(self) -> str:
        return f"R-{self.pk}"


class RequestMessage(models.Model):
    request = models.ForeignKey(ServiceRequest, on_delete=models.CASCADE, related_name="messages")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    body = models.TextField(max_length=2000)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["id"]
        indexes = [models.Index(fields=["request", "id"])]

    def __str__(self) -> str:
        return f"message#{self.pk} on request {self.request_id}"
