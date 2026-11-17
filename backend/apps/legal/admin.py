from django.contrib import admin

from apps.core.admin_site import PolicyAdmin

from .models import LegalDocument


@admin.register(LegalDocument)
class LegalDocumentAdmin(PolicyAdmin):
    list_display = ("kind", "language", "title", "updated_at")
    list_filter = ("kind", "language")
