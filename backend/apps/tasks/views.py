from django.db.models import Case, IntegerField, Q, When
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import status
from rest_framework.generics import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.pagination import StandardPagination
from apps.core.policies import Role

from . import services
from .access import visible_tasks
from .models import Task
from .serializers import (
    AssigneesSerializer,
    CommentSerializer,
    HistorySerializer,
    TaskCreateSerializer,
    TaskSerializer,
    TaskUpdateSerializer,
    TransitionSerializer,
)

ORDERINGS = {"created_at", "-created_at", "due_date", "-due_date", "priority", "-priority", "status", "-status"}


def task_queryset(user):
    return visible_tasks(user).select_related("creator", "client").prefetch_related("assignments__worker")


def get_task(request, pk) -> Task:
    """404 for both missing and forbidden ids so ids cannot be probed (IDOR)."""
    return get_object_or_404(task_queryset(request.user), pk=pk)


class TaskList(APIView):
    @extend_schema(
        tags=["tasks"],
        parameters=[
            OpenApiParameter("status", str, description="One status or a comma list, e.g. `OPEN,IN_PROGRESS`."),
            OpenApiParameter("priority", str, description="One priority or a comma list."),
            OpenApiParameter("project", str),
            OpenApiParameter("client", int),
            OpenApiParameter("worker", int, description="Active assignee id."),
            OpenApiParameter("due_before", str, description="YYYY-MM-DD"),
            OpenApiParameter("due_after", str, description="YYYY-MM-DD"),
            OpenApiParameter("q", str, description="Search in title and description."),
            OpenApiParameter("ordering", str, description="created_at, due_date, priority, status; `-` prefix = desc."),
        ],
        responses=TaskSerializer(many=True),
    )  # fmt: skip
    def get(self, request):
        qs, p = task_queryset(request.user), request.query_params
        for field in ("status", "priority"):  # comma list allowed: ?status=OPEN,IN_PROGRESS
            values = [v.strip().upper() for v in p.get(field, "").split(",") if v.strip()]
            if values:
                qs = qs.filter(**{f"{field}__in": values})
        for field in ("project", "client"):
            if p.get(field):
                qs = qs.filter(**{field: p[field]})
        if p.get("worker"):
            qs = qs.filter(assignments__worker_id=p["worker"], assignments__unassigned_at__isnull=True)
        if p.get("due_before"):
            qs = qs.filter(due_date__lte=p["due_before"])
        if p.get("due_after"):
            qs = qs.filter(due_date__gte=p["due_after"])
        if p.get("q"):
            qs = qs.filter(Q(title__icontains=p["q"]) | Q(description__icontains=p["q"]))
        ordering = p["ordering"] if p.get("ordering") in ORDERINGS else "-created_at"
        if ordering.lstrip("-") == "priority":  # rank, not alphabetical: HIGH > MEDIUM > LOW
            rank = Case(
                When(priority="HIGH", then=3), When(priority="MEDIUM", then=2), default=1, output_field=IntegerField()
            )
            qs = qs.annotate(priority_rank=rank)
            ordering = "-priority_rank" if ordering.startswith("-") else "priority_rank"
        qs = qs.order_by(ordering, "-id").distinct()
        pager = StandardPagination()
        page = pager.paginate_queryset(qs, request)
        return pager.get_paginated_response(TaskSerializer(page, many=True, context={"request": request}).data)

    @extend_schema(tags=["tasks"], request=TaskCreateSerializer, responses={201: TaskSerializer})
    def post(self, request):
        data = TaskCreateSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        task = services.create_task(request.user, data.validated_data)
        task = task_queryset(request.user).get(pk=task.pk)
        return Response(TaskSerializer(task, context={"request": request}).data, status=status.HTTP_201_CREATED)


class TaskDetail(APIView):
    @extend_schema(tags=["tasks"], responses=TaskSerializer)
    def get(self, request, pk):
        return Response(TaskSerializer(get_task(request, pk), context={"request": request}).data)

    @extend_schema(tags=["tasks"], request=TaskUpdateSerializer, responses=TaskSerializer)
    def patch(self, request, pk):
        get_task(request, pk)
        data = TaskUpdateSerializer(data=request.data, partial=True)
        data.is_valid(raise_exception=True)
        changes = dict(data.validated_data)
        version = changes.pop("version", None)
        services.update_task(request.user, pk, changes, version)
        return Response(TaskSerializer(get_task(request, pk), context={"request": request}).data)


class TaskTransition(APIView):
    """Move a task along its status machine (see `apps/tasks/transitions.py`)."""

    @extend_schema(tags=["tasks"], request=TransitionSerializer, responses=TaskSerializer)
    def post(self, request, pk):
        get_task(request, pk)
        data = TransitionSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        services.transition(
            request.user,
            pk,
            data.validated_data["to_status"],
            data.validated_data.get("reason", ""),
            data.validated_data.get("version"),
        )
        return Response(TaskSerializer(get_task(request, pk), context={"request": request}).data)


class TaskAssignees(APIView):
    @extend_schema(tags=["tasks"], request=AssigneesSerializer, responses=TaskSerializer)
    def put(self, request, pk):
        task = get_task(request, pk)
        data = AssigneesSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        services.set_assignees(request.user, task, data.validated_data["worker_ids"])
        return Response(TaskSerializer(get_task(request, pk), context={"request": request}).data)


class TaskHistoryList(APIView):
    @extend_schema(tags=["tasks"], responses=HistorySerializer(many=True))
    def get(self, request, pk):
        task = get_task(request, pk)
        rows = task.history.select_related("actor")
        return Response(HistorySerializer(rows, many=True).data)


class TaskComments(APIView):
    @extend_schema(tags=["tasks"], responses=CommentSerializer(many=True))
    def get(self, request, pk):
        task = get_task(request, pk)
        rows = task.comments.select_related("author")
        if request.user.role == Role.CLIENT:
            rows = rows.filter(is_internal=False)
        return Response(CommentSerializer(rows, many=True).data)

    @extend_schema(tags=["tasks"], request=CommentSerializer, responses={201: CommentSerializer})
    def post(self, request, pk):
        task = get_task(request, pk)
        data = CommentSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        comment = services.add_comment(
            request.user, task, data.validated_data["body"], data.validated_data.get("is_internal", False)
        )
        return Response(CommentSerializer(comment).data, status=status.HTTP_201_CREATED)
