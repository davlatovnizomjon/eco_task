from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from apps.accounts.models import User
from apps.accounts.serializers import UserBriefSerializer
from apps.core.policies import Cap, Role, can
from apps.files.serializers import AttachmentSerializer
from apps.projects.models import Project

from .models import Currency, Priority, Status, Task, TaskComment, TaskHistory


class TaskSerializer(serializers.ModelSerializer):
    """Read model. `agreed_value` is dropped for anyone who may not see money (workers, assistants)."""

    creator = UserBriefSerializer(read_only=True)
    client = UserBriefSerializer(read_only=True)
    assignees = serializers.SerializerMethodField()
    attachments = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            "id", "title", "description", "creator", "client", "project", "assignees", "status", "priority",
            "start_date", "due_date", "completed_at", "agreed_value", "currency", "failure_reason",
            "client_name", "client_is_org", "address", "remind_at", "attachments", "approved_by",
            "approved_at", "version", "created_at", "updated_at",
        ]  # fmt: skip
        read_only_fields = fields

    @extend_schema_field(UserBriefSerializer(many=True))
    def get_assignees(self, task):
        return UserBriefSerializer(
            [a.worker for a in task.assignments.all() if a.unassigned_at is None], many=True
        ).data

    @extend_schema_field(AttachmentSerializer(many=True))
    def get_attachments(self, task):
        return AttachmentSerializer(task.attachments.all(), many=True).data

    def to_representation(self, task):
        data = super().to_representation(task)
        user = self.context["request"].user
        sees_money = can(user, Cap.VIEW_FINANCE) or (user.role == Role.CLIENT and task.client_id == user.pk)
        if not sees_money:
            data.pop("agreed_value")
            data.pop("currency")
        return data


class TaskCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200)
    description = serializers.CharField(required=False, allow_blank=True, max_length=10000)
    priority = serializers.ChoiceField(choices=Priority.choices, required=False)
    start_date = serializers.DateField(required=False, allow_null=True)
    due_date = serializers.DateField(required=False, allow_null=True)
    client = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role=Role.CLIENT, is_active=True), required=False, allow_null=True
    )
    project = serializers.PrimaryKeyRelatedField(queryset=Project.objects.all(), required=False, allow_null=True)
    agreed_value = serializers.DecimalField(
        max_digits=14, decimal_places=2, min_value=0, required=False, allow_null=True
    )
    currency = serializers.ChoiceField(choices=Currency.choices, required=False)
    client_name = serializers.CharField(max_length=200, required=False, allow_blank=True)
    client_is_org = serializers.BooleanField(required=False)
    address = serializers.CharField(max_length=300, required=False, allow_blank=True)
    remind_at = serializers.DateTimeField(required=False, allow_null=True)
    worker_ids = serializers.ListField(child=serializers.IntegerField(), required=False, max_length=50)
    attachment_ids = serializers.ListField(child=serializers.IntegerField(), required=False, max_length=15)

    def validate(self, attrs):
        start, due = attrs.get("start_date"), attrs.get("due_date")
        if start and due and due < start:
            raise serializers.ValidationError("due_date cannot be before start_date.")
        return attrs


class TaskUpdateSerializer(TaskCreateSerializer):
    title = serializers.CharField(max_length=200, required=False)
    version = serializers.IntegerField(required=False, min_value=1)
    worker_ids = None  # assignments have their own endpoint


class TransitionSerializer(serializers.Serializer):
    to_status = serializers.ChoiceField(choices=Status.choices)
    reason = serializers.CharField(required=False, allow_blank=True, max_length=2000)
    version = serializers.IntegerField(required=False, min_value=1)


class AssigneesSerializer(serializers.Serializer):
    worker_ids = serializers.ListField(child=serializers.IntegerField(), max_length=50)


class HistorySerializer(serializers.ModelSerializer):
    actor = UserBriefSerializer(read_only=True)

    class Meta:
        model = TaskHistory
        fields = ["id", "from_status", "to_status", "actor", "reason", "created_at"]
        read_only_fields = fields


class CommentSerializer(serializers.ModelSerializer):
    author = UserBriefSerializer(read_only=True)

    class Meta:
        model = TaskComment
        fields = ["id", "author", "body", "is_internal", "created_at"]
        read_only_fields = ["id", "author", "created_at"]
