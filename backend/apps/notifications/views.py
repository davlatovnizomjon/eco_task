from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema, inline_serializer
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.pagination import StandardPagination

from .models import DeviceToken, Notification
from .services import register_device, unregister_device


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "kind", "title", "task", "conversation", "service_request", "read_at", "created_at"]
        read_only_fields = fields


class NotificationList(APIView):
    @extend_schema(
        tags=["notifications"],
        parameters=[OpenApiParameter("unread", bool)],
        responses=NotificationSerializer(many=True),
    )
    def get(self, request):
        qs = Notification.objects.filter(user=request.user)  # always scoped to the caller
        if request.query_params.get("unread") in ("1", "true"):
            qs = qs.filter(read_at__isnull=True)
        pager = StandardPagination()
        page = pager.paginate_queryset(qs, request)
        return pager.get_paginated_response(NotificationSerializer(page, many=True).data)


class UnreadCount(APIView):
    @extend_schema(
        tags=["notifications"],
        responses=inline_serializer("UnreadCount", {"unread": serializers.IntegerField()}),
    )
    def get(self, request):
        return Response({"unread": Notification.objects.filter(user=request.user, read_at__isnull=True).count()})


class MarkRead(APIView):
    @extend_schema(
        tags=["notifications"],
        request=inline_serializer(
            "MarkReadRequest", {"ids": serializers.ListField(child=serializers.IntegerField(), required=False)}
        ),
        responses=inline_serializer("MarkReadResult", {"updated": serializers.IntegerField()}),
    )
    def post(self, request):
        qs = Notification.objects.filter(user=request.user, read_at__isnull=True)
        ids = request.data.get("ids")
        if ids is not None:
            if not isinstance(ids, list) or not all(isinstance(i, int) for i in ids):
                return Response(
                    {"error": {"code": "invalid_ids", "message": "ids must be a list of integers."}}, status=400
                )
            qs = qs.filter(pk__in=ids)
        return Response({"updated": qs.update(read_at=timezone.now())})


class DeviceSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=512)
    platform = serializers.ChoiceField(choices=[p for p, _ in DeviceToken.PLATFORMS], required=False)
    language = serializers.CharField(max_length=8, required=False, allow_blank=True, default="")


class Devices(APIView):
    """Register (POST) or forget (DELETE) the push token of the calling device."""

    @extend_schema(tags=["notifications"], request=DeviceSerializer, responses={204: None})
    def post(self, request):
        data = DeviceSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        register_device(
            request.user,
            data.validated_data["token"],
            data.validated_data.get("platform", "android"),
            data.validated_data["language"],
        )
        return Response(status=204)

    @extend_schema(
        tags=["notifications"],
        request=inline_serializer("DeviceForget", {"token": serializers.CharField()}),
        responses={204: None},
    )
    def delete(self, request):
        token = request.data.get("token")
        if not isinstance(token, str) or not token:
            return Response({"error": {"code": "invalid_token", "message": "token is required."}}, status=400)
        unregister_device(request.user, token)
        return Response(status=204)
