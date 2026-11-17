from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.db import models

# Files live outside any web-served directory; they are only ever returned by an authorized view.
private_storage = FileSystemStorage(location=settings.PRIVATE_MEDIA_ROOT)


class Kind(models.TextChoices):
    IMAGE = "IMAGE"
    DOCUMENT = "DOCUMENT"
    AUDIO = "AUDIO"
    VIDEO = "VIDEO"


class Attachment(models.Model):
    """One uploaded file. It is born unattached (owned by its uploader) and later linked to a task, a chat message or a
    conversation avatar; unattached files are visible to their owner only."""

    owner = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    kind = models.CharField(max_length=10, choices=Kind.choices)
    file = models.FileField(storage=private_storage, upload_to="%Y/%m")
    original_name = models.CharField(max_length=200)
    content_type = models.CharField(max_length=100)
    size = models.PositiveIntegerField()
    duration_ms = models.PositiveIntegerField(null=True, blank=True)  # voice notes and video circles
    task = models.ForeignKey("tasks.Task", null=True, blank=True, on_delete=models.CASCADE, related_name="attachments")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["id"]
        indexes = [models.Index(fields=["task", "kind"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(kind__in=[k.value for k in Kind]), name="attachment_kind_valid")
        ]

    def __str__(self) -> str:
        return f"{self.kind} {self.original_name}"
