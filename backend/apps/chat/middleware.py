"""WebSocket handshake: origin policy and bearer-token authentication.

Browsers cannot set an Authorization header on `new WebSocket()`, and tokens in the URL end up in proxy logs, so the
token travels in `Sec-WebSocket-Protocol: bearer, <token>`. Native clients can use the same convention.
"""

from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.conf import settings
from django.contrib.auth.models import AnonymousUser

from apps.accounts.authentication import user_for_raw_token

SUBPROTOCOL = "bearer"


def token_from_subprotocols(subprotocols: list[str]) -> str | None:
    if len(subprotocols) == 2 and subprotocols[0] == SUBPROTOCOL:
        return subprotocols[1]
    return None


class OriginAndAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        if scope["type"] != "websocket":
            return await super().__call__(scope, receive, send)
        headers = dict(scope.get("headers", []))
        origin = headers.get(b"origin", b"").decode()
        # A browser always sends Origin; reject any not on the allow-list. Native clients send none.
        if origin and origin not in settings.WS_ALLOWED_ORIGINS:
            return await self._reject(receive, send)
        raw = token_from_subprotocols(scope.get("subprotocols", []))
        user = await database_sync_to_async(user_for_raw_token)(raw) if raw else None
        scope = {**scope, "user": user or AnonymousUser()}
        return await super().__call__(scope, receive, send)

    @staticmethod
    async def _reject(receive, send):
        await receive()  # consume websocket.connect
        await send({"type": "websocket.close", "code": 4403})
