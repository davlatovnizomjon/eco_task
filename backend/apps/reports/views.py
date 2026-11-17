from django.http import HttpResponse
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.tasks.access import visible_tasks
from apps.tasks.serializers import TaskSerializer

from . import services


class StatsQuerySerializer(serializers.Serializer):
    kind = serializers.ChoiceField(choices=services.KINDS)
    period = serializers.ChoiceField(choices=services.PERIODS, default="month")
    offset = serializers.IntegerField(max_value=0, min_value=-120, default=0)
    currency = serializers.ChoiceField(choices=["UZS", "USD"], required=False)


class StatsView(APIView):
    @extend_schema(
        tags=["reports"],
        parameters=[
            OpenApiParameter("kind", str, description="finance, tasks, mine, clients, staff or managers."),
            OpenApiParameter("period", str, description="week, month or year."),
            OpenApiParameter("offset", int, description="Windows back from the current one: 0, -1, -2, ..."),
            OpenApiParameter("currency", str, description="Money screens: UZS (default) or USD."),
        ],
        responses=dict,
    )
    def get(self, request):
        q = StatsQuerySerializer(data=request.query_params)
        q.is_valid(raise_exception=True)
        return Response(services.stats(request.user, **q.validated_data))


class ExportView(APIView):
    @extend_schema(tags=["reports"], request=StatsQuerySerializer, responses={200: str})
    def post(self, request):
        q = StatsQuerySerializer(data=request.data)
        q.is_valid(raise_exception=True)
        body = services.export_csv(request.user, **q.validated_data)
        response = HttpResponse(body, content_type="text/csv; charset=utf-8")
        d = q.validated_data
        response["Content-Disposition"] = f'attachment; filename="{d["kind"]}-{d["period"]}{d["offset"]}.csv"'
        return response


class DashboardView(APIView):
    @extend_schema(tags=["reports"], responses=dict)
    def get(self, request):
        data = services.dashboard(request.user)
        due = list(visible_tasks(request.user).filter(pk__in=data["due_today"]).select_related("creator", "client"))
        due.sort(key=lambda t: data["due_today"].index(t.pk))
        data["due_today"] = TaskSerializer(due, many=True, context={"request": request}).data
        return Response(data)
