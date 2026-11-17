from rest_framework import serializers

from .models import Attachment


class AttachmentSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source="original_name", read_only=True)
    url = serializers.SerializerMethodField()

    class Meta:
        model = Attachment
        fields = ["id", "kind", "name", "content_type", "size", "duration_ms", "url", "created_at"]
        read_only_fields = fields

    def get_url(self, attachment) -> str:
        return f"/api/v1/files/{attachment.pk}/"


class UploadSerializer(serializers.Serializer):
    file = serializers.FileField()
    duration_ms = serializers.IntegerField(required=False, min_value=0, max_value=3_600_000)
