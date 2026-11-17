from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.errors import DomainError

from .models import AppRelease
from .serializers import AppVersionQuerySerializer, AppVersionSerializer


class AppVersionView(APIView):
    """Latest app version of a platform. Public: it must answer before anybody has signed in."""

    authentication_classes: list = []
    permission_classes = [AllowAny]

    @extend_schema(
        tags=["app"],
        parameters=[OpenApiParameter("platform", str, enum=["android", "ios"], required=True)],
        responses={200: AppVersionSerializer},
        auth=[],
    )
    def get(self, request):
        query = AppVersionQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        release = AppRelease.objects.filter(platform=query.validated_data["platform"]).first()
        if release is None:
            raise DomainError("No release is published for this platform.", "release_not_found", 404)
        return Response(AppVersionSerializer(release).data)
