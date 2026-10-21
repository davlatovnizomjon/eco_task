"""One stable error envelope: {"error": {"code": ..., "detail": ...}}."""

import logging

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError
from rest_framework.views import exception_handler as drf_handler

logger = logging.getLogger(__name__)


class DomainError(Exception):
    """A business-rule violation; mapped to HTTP 409/400 by the handler."""

    def __init__(self, detail: str, code: str = "invalid_operation", status: int = 400):
        super().__init__(detail)
        self.detail, self.code, self.status = detail, code, status


def exception_handler(exc, context):
    from rest_framework.response import Response

    if isinstance(exc, DomainError):
        return Response({"error": {"code": exc.code, "detail": exc.detail}}, status=exc.status)
    if isinstance(exc, DjangoValidationError):  # e.g. password validators called from services
        exc = ValidationError(exc.messages)
    response = drf_handler(exc, context)
    if response is None:
        logger.exception("unhandled error")  # message only; no request body is logged
        return None
    detail = response.data
    code = getattr(getattr(exc, "detail", None), "code", None) or getattr(exc, "default_code", "error")
    response.data = {"error": {"code": str(code), "detail": detail}}
    return response
