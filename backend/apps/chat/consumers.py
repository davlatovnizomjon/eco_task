import json
import logging
import time

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.conf import settings
from django.core.cache import cache

from apps.core.errors import DomainError

from . import services
from .middleware import SUBPROTOCOL
from .models import Conversation, Membership

logger = logging.getLogger(__name__)

MAX_FRAME_BYTES = 16 * 1024
CLOSE_UNAUTHENTICATED, CLOSE_FORBIDDEN, CLOSE_TOO_MANY = 4401, 4403, 4429


class ChatConsumer(AsyncJsonWebsocketConsumer):
    """One socket = one authenticated user in one conversation. Sender identity always comes from the scope."""

    conversation: Conversation | None = None
    joined = False

    async def connect(self):
        user = self.scope["user"]
        if not user.is_authenticated:
            return await self.close(code=CLOSE_UNAUTHENTICATED)
        self.user_id = user.pk
        try:
            conversation = await database_sync_to_async(services.get_conversation_for)(
                user, self.scope["url_route"]["kwargs"]["conversation_id"]
            )
        except DomainError:
            return await self.close(code=CLOSE_FORBIDDEN)  # same code for "missing" and "forbidden"
        if not self._take_connection_slot():
            return await self.close(code=CLOSE_TOO_MANY)
        self.conversation = conversation
        self.group = services.group_name(conversation.pk)
        self.own_group = services.user_group(user.pk)
        await self.channel_layer.group_add(self.group, self.channel_name)
        await self.channel_layer.group_add(self.own_group, self.channel_name)
        self.joined = True
        await self.accept(subprotocol=SUBPROTOCOL)
        await self._announce_presence(online=True)
        await self.send_json({"type": "presence.snapshot", "online": await self._online_members()})

    async def disconnect(self, code):
        if not self.joined:
            return
        await self.channel_layer.group_discard(self.group, self.channel_name)
        await self.channel_layer.group_discard(self.own_group, self.channel_name)
        self._release_connection_slot()
        await self._announce_presence(online=False)

    # --- inbound ---------------------------------------------------------------------------
    async def receive(self, text_data=None, bytes_data=None, **kwargs):
        if bytes_data is not None or text_data is None or len(text_data) > MAX_FRAME_BYTES:
            return await self.close(code=1009)
        try:
            frame = json.loads(text_data)
        except ValueError:
            return await self._error("invalid_json")
        if not isinstance(frame, dict):
            return await self._error("invalid_frame")
        kind = frame.get("type")
        if kind == "ping":
            return await self.send_json({"type": "pong"})
        if kind not in ("message.send", "message.read"):
            return await self._error("unknown_type")
        if not self._within_rate_limit():
            return await self._error("rate_limited")
        user = self.scope["user"]
        try:
            conversation = await database_sync_to_async(services.get_conversation_for)(user, self.conversation.pk)
            if kind == "message.send":
                await self._handle_send(user, conversation, frame)
            else:
                message_id = frame.get("message_id")
                if not isinstance(message_id, int) or isinstance(message_id, bool) or message_id < 1:
                    return await self._error("invalid_message_id")
                await database_sync_to_async(services.mark_read)(user, conversation, message_id)
        except DomainError as exc:
            if exc.status == 404:  # lost access since connecting
                return await self.close(code=CLOSE_FORBIDDEN)
            await self._error(exc.code)

    async def _handle_send(self, user, conversation, frame):
        body, client_id = frame.get("body"), frame.get("client_msg_id", "")
        if not isinstance(body, str) or not isinstance(client_id, str) or len(client_id) > 64:
            return await self._error("invalid_message")
        message, created = await database_sync_to_async(services.send_message)(user, conversation, body, client_id)
        # The broadcast already reached the group (including this socket). The ack carries the stored id so the
        # client can reconcile its optimistic copy, and repeats for idempotent retries.
        await self.send_json({"type": "message.ack", "client_msg_id": client_id, "id": message.pk, "duplicate": not created})

    # --- group events ----------------------------------------------------------------------
    async def chat_message(self, event):
        await self.send_json({"type": "message.new", "message": event["message"]})

    async def chat_read(self, event):
        await self.send_json({"type": "message.read", "user": event["user"], "message_id": event["message_id"]})

    async def chat_presence(self, event):
        if event["user"] == self.user_id:
            return  # own presence is not news to oneself
        await self.send_json({"type": "presence", "user": event["user"], "online": event["online"]})

    async def chat_revoke(self, event):
        if event["conversation"] == str(self.conversation.pk):
            await self.send_json({"type": "revoked"})
            await self.close(code=CLOSE_FORBIDDEN)

    # --- helpers ---------------------------------------------------------------------------
    async def _error(self, code: str):
        await self.send_json({"type": "error", "code": code})  # generic code only; never echoes message content

    def _within_rate_limit(self) -> bool:
        key = f"ws:rate:{self.user_id}:{int(time.time() // 60)}"
        cache.add(key, 0, timeout=90)
        return cache.incr(key) <= settings.CHAT_MESSAGES_PER_MINUTE

    def _take_connection_slot(self) -> bool:
        key = f"ws:conn:{self.user_id}"
        cache.add(key, 0, timeout=3600)
        if cache.incr(key) > settings.WS_MAX_CONNECTIONS_PER_USER:
            cache.decr(key)
            return False
        return True

    def _release_connection_slot(self):
        key = f"ws:conn:{self.user_id}"
        try:
            if cache.decr(key) < 0:
                cache.set(key, 0, timeout=3600)
        except ValueError:
            pass

    async def _announce_presence(self, online: bool):
        key = f"presence:{self.conversation.pk}:{self.user_id}"
        cache.add(key, 0, timeout=3600)
        count = cache.incr(key) if online else max(cache.decr(key), 0)
        if (online and count == 1) or (not online and count == 0):
            await self.channel_layer.group_send(
                self.group, {"type": "chat.presence", "user": self.user_id, "online": online}
            )

    @database_sync_to_async
    def _online_members(self) -> list[int]:
        ids = Membership.objects.filter(conversation=self.conversation, left_at__isnull=True).values_list(
            "user_id", flat=True
        )
        return [uid for uid in ids if (cache.get(f"presence:{self.conversation.pk}:{uid}") or 0) > 0]
