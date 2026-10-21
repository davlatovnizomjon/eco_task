from rest_framework import serializers

from .models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    actor = serializers.StringRelatedField()

    class Meta:
        model = AuditLog
        fields = ["id", "created_at", "actor", "action", "target_type", "target_id", "metadata"]
        read_only_fields = fields
