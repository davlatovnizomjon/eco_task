"""Uploads and the rule of who may read a file. Content is never trusted: the type is checked against an allow-list
and, for images, against the file's own header."""

import logging
import os
import uuid

from django.conf import settings
from django.core.files.base import ContentFile

from apps.accounts.models import User
from apps.core.errors import DomainError

from .models import Attachment, Kind

logger = logging.getLogger(__name__)

IMAGE_TYPES = {"image/jpeg": (b"\xff\xd8\xff",), "image/png": (b"\x89PNG",), "image/webp": (b"RIFF",), "image/heic": ()}
AUDIO_TYPES = {"audio/mpeg", "audio/mp4", "audio/aac", "audio/ogg", "audio/webm", "audio/x-m4a", "audio/wav"}
VIDEO_TYPES = {"video/mp4", "video/quicktime", "video/webm"}
DOCUMENT_TYPES = {
    "application/pdf",
    "text/plain",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
}
MAX_TASK_IMAGES, MAX_TASK_DOCS = 10, 5


def kind_of(content_type: str) -> str:
    if content_type in IMAGE_TYPES:
        return Kind.IMAGE
    if content_type in AUDIO_TYPES:
        return Kind.AUDIO
    if content_type in VIDEO_TYPES:
        return Kind.VIDEO
    if content_type in DOCUMENT_TYPES:
        return Kind.DOCUMENT
    raise DomainError("This file type is not allowed.", "file_type_not_allowed", 415)


def store_upload(owner: User, upload, duration_ms: int | None = None) -> Attachment:
    content_type = (upload.content_type or "").split(";")[0].strip().lower()
    kind = kind_of(content_type)
    if upload.size > settings.UPLOAD_MAX_BYTES:
        raise DomainError("The file is too large.", "file_too_large", 413)
    if upload.size == 0:
        raise DomainError("The file is empty.", "file_empty", 400)
    head = upload.read(16)
    upload.seek(0)
    if kind == Kind.IMAGE and IMAGE_TYPES[content_type] and not head.startswith(IMAGE_TYPES[content_type]):
        raise DomainError("The file is not a valid image.", "file_invalid", 400)
    name = os.path.basename(upload.name or "file")[:200] or "file"
    stored = f"{uuid.uuid4().hex}{os.path.splitext(name)[1][:10].lower()}"
    attachment = Attachment(
        owner=owner, kind=kind, original_name=name, content_type=content_type, size=upload.size, duration_ms=duration_ms
    )
    attachment.file.save(stored, ContentFile(upload.read()), save=False)
    attachment.save()
    return attachment


def can_read(user: User, attachment: Attachment) -> bool:
    """Owner while unattached; otherwise whoever may see the thing it is attached to."""
    from apps.chat.models import Conversation, Message
    from apps.chat.services import can_access
    from apps.tasks.access import can_view_task

    if not user.is_authenticated or not user.is_active:
        return False
    if attachment.owner_id == user.pk:
        return True
    if attachment.task_id:
        return can_view_task(user, attachment.task_id)
    for message in Message.objects.filter(attachment=attachment).select_related("conversation")[:1]:
        return can_access(user, message.conversation)
    for conversation in Conversation.objects.filter(avatar=attachment)[:1]:
        return can_access(user, conversation)
    return False


def remove_file(attachment: Attachment) -> None:
    """Delete the stored file and the row (best effort for the file; the row is authoritative)."""
    try:
        attachment.file.delete(save=False)
    except OSError:
        logger.exception("could not remove file of attachment %s", attachment.pk)
    attachment.delete()
