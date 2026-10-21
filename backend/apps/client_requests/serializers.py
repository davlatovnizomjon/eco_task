from rest_framework import serializers

from apps.accounts.models import User
from apps.accounts.serializers import UserBriefSerializer

from .models import Kind, RequestMessage, ServiceRequest, Status


class ServiceRequestSerializer(serializers.ModelSerializer):
    code = serializers.CharField(read_only=True)
    client = UserBriefSerializer(read_only=True)
    assignee = UserBriefSerializer(read_only=True)

    class Meta:
        model = ServiceRequest
        fields = [
            "id", "code", "client", "title", "detail", "kind", "address", "date", "slot", "status",
            "assignee", "created_at", "updated_at",
        ]  # fmt: skip
        read_only_fields = fields


class ServiceRequestCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200)
    detail = serializers.CharField(required=False, allow_blank=True, max_length=5000)
    kind = serializers.ChoiceField(choices=Kind.choices, required=False)
    address = serializers.CharField(max_length=300)
    date = serializers.DateField(required=False, allow_null=True)
    slot = serializers.CharField(required=False, allow_blank=True, max_length=20)


class ServiceRequestUpdateSerializer(serializers.Serializer):
    """Staff-only fields; everything else about a request is the client's wording and stays untouched."""

    status = serializers.ChoiceField(choices=Status.choices, required=False)
    assignee = serializers.PrimaryKeyRelatedField(queryset=User.objects.all(), required=False, allow_null=True)
    date = serializers.DateField(required=False, allow_null=True)
    slot = serializers.CharField(required=False, allow_blank=True, max_length=20)


class RequestMessageSerializer(serializers.ModelSerializer):
    author = UserBriefSerializer(read_only=True)
    body = serializers.CharField(max_length=2000)

    class Meta:
        model = RequestMessage
        fields = ["id", "author", "body", "created_at"]
        read_only_fields = ["id", "author", "created_at"]
