from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import status
from rest_framework.generics import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.pagination import StandardPagination

from . import services
from .access import visible_requests
from .serializers import (
    RequestMessageSerializer,
    ServiceRequestCreateSerializer,
    ServiceRequestSerializer,
    ServiceRequestUpdateSerializer,
)


def get_request(request, pk):
    """404 for both missing and foreign ids so ids cannot be probed (IDOR)."""
    return get_object_or_404(visible_requests(request.user).select_related("client", "assignee"), pk=pk)


class RequestList(APIView):
    @extend_schema(
        tags=["requests"],
        parameters=[
            OpenApiParameter("status", str, description="One status or a comma list."),
            OpenApiParameter("q", str, description="Search in title and address."),
        ],
        responses=ServiceRequestSerializer(many=True),
    )
    def get(self, request):
        qs = visible_requests(request.user).select_related("client", "assignee")
        p = request.query_params
        values = [v.strip().upper() for v in p.get("status", "").split(",") if v.strip()]
        if values:
            qs = qs.filter(status__in=values)
        if p.get("q"):
            qs = qs.filter(title__icontains=p["q"]) | qs.filter(address__icontains=p["q"])
        pager = StandardPagination()
        page = pager.paginate_queryset(qs.order_by("-created_at", "-id"), request)
        return pager.get_paginated_response(ServiceRequestSerializer(page, many=True).data)

    @extend_schema(tags=["requests"], request=ServiceRequestCreateSerializer, responses={201: ServiceRequestSerializer})
    def post(self, request):
        data = ServiceRequestCreateSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        created = services.create_request(request.user, data.validated_data)
        return Response(ServiceRequestSerializer(get_request(request, created.pk)).data, status=status.HTTP_201_CREATED)


class RequestDetail(APIView):
    @extend_schema(tags=["requests"], responses=ServiceRequestSerializer)
    def get(self, request, pk):
        return Response(ServiceRequestSerializer(get_request(request, pk)).data)

    @extend_schema(tags=["requests"], request=ServiceRequestUpdateSerializer, responses=ServiceRequestSerializer)
    def patch(self, request, pk):
        get_request(request, pk)
        data = ServiceRequestUpdateSerializer(data=request.data, partial=True)
        data.is_valid(raise_exception=True)
        services.update_request(request.user, pk, dict(data.validated_data))
        return Response(ServiceRequestSerializer(get_request(request, pk)).data)


class RequestMessages(APIView):
    @extend_schema(tags=["requests"], responses=RequestMessageSerializer(many=True))
    def get(self, request, pk):
        rows = get_request(request, pk).messages.select_related("author")
        return Response(RequestMessageSerializer(rows, many=True).data)

    @extend_schema(tags=["requests"], request=RequestMessageSerializer, responses={201: RequestMessageSerializer})
    def post(self, request, pk):
        target = get_request(request, pk)
        data = RequestMessageSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        message = services.add_message(request.user, target, data.validated_data["body"])
        return Response(RequestMessageSerializer(message).data, status=status.HTTP_201_CREATED)
