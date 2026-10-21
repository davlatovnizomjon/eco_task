import os

os.environ.setdefault("DJANGO_SECRET_KEY", "test-only-secret-key-not-for-use-anywhere-else-0123456789")
os.environ.setdefault("DB_ENGINE", os.environ.get("TEST_DB_ENGINE", "sqlite"))

from .base import *  # noqa: E402, F403

ALLOWED_HOSTS = ["testserver", "localhost"]
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]  # speed only; never outside tests
PRIVATE_MEDIA_ROOT = BASE_DIR / ".test_media"  # noqa: F405
DEFAULT_THROTTLE = REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"]  # noqa: F405
