import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.prod")
django_asgi = get_asgi_application()  # must run before importing app routing

from apps.chat.middleware import OriginAndAuthMiddleware  # noqa: E402
from apps.chat.routing import websocket_urlpatterns  # noqa: E402
from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402

application = ProtocolTypeRouter(
    {"http": django_asgi, "websocket": OriginAndAuthMiddleware(URLRouter(websocket_urlpatterns))}
)
