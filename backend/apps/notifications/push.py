"""Push delivery through Firebase Cloud Messaging (FCM).

Push is best effort and strictly optional: with no `FIREBASE_CREDENTIALS_FILE` configured nothing is sent and nothing
fails. The inbox row (`Notification`) is the source of truth; a push only nudges the device to open the app.
Sending runs on a small thread pool after the surrounding transaction commits, so a slow or failing FCM call can never
delay or roll back the request that produced the notification.
"""

import logging
import threading
from concurrent.futures import ThreadPoolExecutor

from django.conf import settings
from django.db import connection, transaction

from .models import DeviceToken

logger = logging.getLogger(__name__)

_executor = ThreadPoolExecutor(max_workers=2, thread_name_prefix="push")
_init_lock = threading.Lock()
_app = None
APP_TITLE = "Eco Tasks"


def enabled() -> bool:
    return bool(settings.FIREBASE_CREDENTIALS_FILE)


def _firebase_app():
    """The shared firebase-admin app, created on first use from the service-account file."""
    global _app
    with _init_lock:
        if _app is None:
            import firebase_admin
            from firebase_admin import credentials

            _app = firebase_admin.initialize_app(credentials.Certificate(settings.FIREBASE_CREDENTIALS_FILE))
    return _app


def queue_push(user_ids, body: str, data: dict[str, str]) -> None:
    """Send `body` to every device of `user_ids` once the current transaction has committed."""
    ids = list(user_ids)
    if not enabled() or not ids:
        return
    transaction.on_commit(lambda: _executor.submit(_deliver, ids, body[:200], data))


def _deliver(user_ids: list[int], body: str, data: dict[str, str]) -> None:
    try:
        _send(user_ids, body, data)
    except Exception:  # noqa: BLE001 - push must never raise into the worker pool silently
        logger.exception("push delivery failed")
    finally:
        connection.close()  # this thread owns its own DB connection


def _send(user_ids: list[int], body: str, data: dict[str, str]) -> None:
    from firebase_admin import messaging

    tokens = list(DeviceToken.objects.filter(user_id__in=user_ids).values_list("token", flat=True))
    if not tokens:
        return
    app = _firebase_app()
    messages = [
        messaging.Message(
            token=token,
            notification=messaging.Notification(title=APP_TITLE, body=body),
            data=data,
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(payload=messaging.APNSPayload(aps=messaging.Aps(sound="default"))),
        )
        for token in tokens
    ]
    dead: list[str] = []
    for token, response in zip(tokens, messaging.send_each(messages, app=app).responses, strict=True):
        if response.success:
            continue
        if isinstance(response.exception, messaging.UnregisteredError | messaging.SenderIdMismatchError):
            dead.append(token)  # the app was uninstalled or the token rotated
        else:
            logger.warning("push to one device failed: %s", response.exception)
    if dead:
        DeviceToken.objects.filter(token__in=dead).delete()
