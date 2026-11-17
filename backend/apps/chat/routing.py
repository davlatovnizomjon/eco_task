from django.urls import path

from .consumers import ChatConsumer, UserConsumer

websocket_urlpatterns = [
    path("ws/chat/<uuid:conversation_id>/", ChatConsumer.as_asgi()),
    path("ws/me/", UserConsumer.as_asgi()),
]
