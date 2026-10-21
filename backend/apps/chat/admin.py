from django.contrib import admin

from apps.core.admin_site import ReadOnlyAdmin, ReadOnlyInline

from .models import Conversation, Membership


class MembershipInline(ReadOnlyInline):
    model = Membership


@admin.register(Conversation)
class ConversationAdmin(ReadOnlyAdmin):
    """Messages are deliberately not registered: their bodies are private to the participants."""

    list_display = ("id", "kind", "title", "task", "created_by", "created_at")
    list_filter = ("kind",)
    search_fields = ("title", "created_by__username")
    inlines = (MembershipInline,)
