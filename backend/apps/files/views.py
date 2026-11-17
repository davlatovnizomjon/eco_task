from django.http import FileResponse
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.generics import get_object_or_404
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from . import services
from .models import Attachment, Kind
from .serializers import AttachmentSerializer, UploadSerializer


class FileUpload(APIView):
    parser_classes = [MultiPartParser]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "upload"

    @extend_schema(tags=["files"], request=UploadSerializer, responses={201: AttachmentSerializer})
    def post(self, request):
        data = UploadSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        attachment = services.store_upload(
            request.user, data.validated_data["file"], data.validated_data.get("duration_ms")
        )
        return Response(AttachmentSerializer(attachment).data, status=status.HTTP_201_CREATED)


class FileDownload(APIView):
    @extend_schema(tags=["files"], responses={200: bytes})
    def get(self, request, pk):
        attachment = get_object_or_404(Attachment, pk=pk)
        if not services.can_read(request.user, attachment):
            get_object_or_404(Attachment, pk=-1)  # same 404 as a missing id
        inline = attachment.kind in (Kind.IMAGE, Kind.AUDIO, Kind.VIDEO)
        response = FileResponse(
            attachment.file.open("rb"),
            content_type=attachment.content_type,
            as_attachment=not inline,
            filename=attachment.original_name,
        )
        response["Cache-Control"] = "private, max-age=3600"
        response["X-Content-Type-Options"] = "nosniff"
        return response
