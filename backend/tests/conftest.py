import sys
import types

# channels.testing imports daphne unconditionally (for its live-server helper). We serve with uvicorn and only need
# WebsocketCommunicator, so a stub keeps daphne (and its Twisted stack) out of the dependency set.
try:
    import daphne.testing  # noqa: F401
except ImportError:
    _daphne = types.ModuleType("daphne")
    _testing = types.ModuleType("daphne.testing")
    _testing.DaphneProcess = object
    _daphne.testing = _testing
    sys.modules.setdefault("daphne", _daphne)
    sys.modules.setdefault("daphne.testing", _testing)

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from apps.accounts.models import AuthToken, User
from apps.core.policies import Role

PASSWORD = "Str0ng-Test-Passphrase!"


@pytest.fixture(autouse=True)
def _clear_cache():
    cache.clear()
    yield
    cache.clear()


def make_user(username: str, role: Role, **extra) -> User:
    return User.objects.create_user(username=username, password=PASSWORD, role=role.value, **extra)


@pytest.fixture
def owner(db):
    return make_user("owner", Role.OWNER)


@pytest.fixture
def assistant(db):
    return make_user("assistant", Role.ASSISTANT)


@pytest.fixture
def worker(db):
    return make_user("worker", Role.WORKER)


@pytest.fixture
def worker2(db):
    return make_user("worker2", Role.WORKER)


@pytest.fixture
def client_user(db):
    return make_user("client", Role.CLIENT)


@pytest.fixture
def client2(db):
    return make_user("client2", Role.CLIENT)


def api_as(user: User) -> APIClient:
    _, raw, _ = AuthToken.issue(user)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {raw}")
    return client


@pytest.fixture
def as_user():
    return api_as
