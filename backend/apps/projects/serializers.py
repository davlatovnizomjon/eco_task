from rest_framework import serializers

from apps.accounts.models import User
from apps.core.policies import Role

from .models import Project


class ProjectSerializer(serializers.ModelSerializer):
    client = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role=Role.CLIENT, is_active=True), required=False, allow_null=True
    )

    class Meta:
        model = Project
        fields = ["id", "name", "description", "client", "is_active", "created_at"]
        read_only_fields = ["id", "created_at"]
