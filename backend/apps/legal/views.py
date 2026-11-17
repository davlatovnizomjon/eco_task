from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.errors import DomainError
from apps.core.language import requested_language

from .models import DocumentKind, Language, LegalDocument
from .serializers import LegalDocumentSerializer


class LegalDocumentView(APIView):
    """A legal text. Public: it is shown on the sign-in screen, before anybody has a token."""

    authentication_classes: list = []
    permission_classes = [AllowAny]
    kind: str = ""

    @extend_schema(
        tags=["app"],
        parameters=[
            OpenApiParameter("Accept-Language", str, OpenApiParameter.HEADER, enum=Language.values, required=False)
        ],
        responses={200: LegalDocumentSerializer},
        auth=[],
    )
    def get(self, request):
        documents = LegalDocument.objects.filter(kind=self.kind)
        # Fall back to Uzbek (the source language) when the requested translation is not published yet.
        document = (
            documents.filter(language=requested_language(request)).first()
            or documents.filter(language=Language.UZ).first()
        )
        if document is None:
            raise DomainError("This document is not published.", "legal_document_not_found", 404)
        return Response(LegalDocumentSerializer(document).data)


class TermsView(LegalDocumentView):
    kind = DocumentKind.TERMS


class PrivacyView(LegalDocumentView):
    kind = DocumentKind.PRIVACY
