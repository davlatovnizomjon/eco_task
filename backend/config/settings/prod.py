from django.core.exceptions import ImproperlyConfigured

from config import env

from .base import *  # noqa: F403

DEBUG = False
if not ALLOWED_HOSTS:  # noqa: F405
    raise ImproperlyConfigured("DJANGO_ALLOWED_HOSTS must be set in production.")
if not REDIS_URL:  # noqa: F405
    raise ImproperlyConfigured("REDIS_URL must be set: in-memory channel layers are not valid in production.")
if len(SECRET_KEY) < 50 or SECRET_KEY.startswith("change"):  # noqa: F405
    raise ImproperlyConfigured("DJANGO_SECRET_KEY is too short or still a placeholder.")

CSRF_TRUSTED_ORIGINS = env.csv("CSRF_TRUSTED_ORIGINS")
SECURE_SSL_REDIRECT = env.boolean("SECURE_SSL_REDIRECT", True)
# Only trust the proxy header when the deployment really sits behind a controlled TLS-terminating proxy.
if env.boolean("BEHIND_TLS_PROXY", True):
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
SECURE_HSTS_SECONDS = env.integer("SECURE_HSTS_SECONDS", 31536000)
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "same-origin"
X_FRAME_OPTIONS = "DENY"
