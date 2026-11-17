"""One stable error envelope: {"error": {"code": ..., "message": ...}}; `message` follows `Accept-Language`."""

import logging

from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework.exceptions import ValidationError
from rest_framework.views import exception_handler as drf_handler

from .language import requested_language
from .messages import localized

logger = logging.getLogger(__name__)


class DomainError(Exception):
    """A business-rule violation; mapped to HTTP 409/400 by the handler."""

    def __init__(self, detail: str, code: str = "invalid_operation", status: int = 400, extra: dict | None = None):
        super().__init__(detail)
        self.detail, self.code, self.status = detail, code, status
        self.extra = extra or {}  # machine-readable fields merged into the error object (e.g. `retry_after`)


def exception_handler(exc, context):
    from rest_framework.response import Response

    request = context.get("request")
    language = requested_language(request) if request is not None else "uz"
    if isinstance(exc, DomainError):
        texts = localized(exc.code, language, exc.extra.get("retry_after"))
        error = {
            "code": exc.code,
            **({"title": texts[0]} if texts else {}),
            "message": texts[1] if texts else exc.detail,
        }
        response = Response({"error": {**error, **exc.extra}}, status=exc.status)
        if "retry_after" in exc.extra:
            response["Retry-After"] = str(exc.extra["retry_after"])
        return response
    if isinstance(exc, DjangoValidationError):  # e.g. password validators called from services
        exc = ValidationError(exc.messages)
    response = drf_handler(exc, context)
    if response is None:
        logger.exception("unhandled error")  # message only; no request body is logged
        return None
    code = str(getattr(getattr(exc, "detail", None), "code", None) or getattr(exc, "default_code", "error"))
    # Validation errors keep their field map; single-sentence errors get the translated texts when they exist.
    texts = localized(code, language)
    response.data = {
        "error": {
            "code": code,
            **({"title": texts[0]} if texts else {}),
            "message": texts[1] if texts else response.data,
        }
    }
    return response
