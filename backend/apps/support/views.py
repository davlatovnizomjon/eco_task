from drf_spectacular.utils import extend_schema
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.core.errors import DomainError

from .models import SupportContact
from .serializers import SupportContactSerializer


class SupportContactView(APIView):
    """Dispatcher phone and Telegram. Public: the sign-in screen shows it to people who cannot sign in."""

    authentication_classes: list = []
    permission_classes = [AllowAny]

    @extend_schema(tags=["app"], responses={200: SupportContactSerializer}, auth=[])
    def get(self, request):
        contact = SupportContact.objects.first()
        if contact is None:
            raise DomainError("Support contacts are not published.", "support_not_found", 404)
        return Response(SupportContactSerializer(contact).data)
