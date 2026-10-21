from django.conf import settings
from django.db import models


class Project(models.Model):
    """A body of work, optionally tied to one client. Deactivated rather than deleted to keep history intact."""

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    client = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name="client_projects"
    )
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name", "id"]
        constraints = [
            models.UniqueConstraint(fields=["client", "name"], name="project_unique_name_per_client"),
            models.UniqueConstraint(
                fields=["name"], condition=models.Q(client__isnull=True), name="project_unique_name_without_client"
            ),
        ]

    def __str__(self) -> str:
        return self.name
