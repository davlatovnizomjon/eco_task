from rest_framework import serializers

from .models import LegalDocument


class LegalDocumentSerializer(serializers.ModelSerializer):
    """The legal text exactly as the app shows it."""

    class Meta:
        model = LegalDocument
        fields = ["title", "message", "updated_at"]
        read_only_fields = fields
