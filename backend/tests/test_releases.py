import pytest
from django.core.exceptions import ValidationError

from apps.releases.models import AppRelease, validate_version

pytestmark = pytest.mark.django_db

URL = "/api/v1/app-version/"


def test_version_is_public_and_returns_the_platform_release():
    AppRelease.objects.create(
        platform="android",
        latest_version="1.4.0",
        force_update=True,
        store_url="https://play.google.com/x",
        title="Yangi versiya chiqdi",
        subtitle="Xatolar tuzatildi.",
    )
    AppRelease.objects.create(platform="ios", latest_version="1.3.0")
    from rest_framework.test import APIClient

    r = APIClient().get(URL, {"platform": "android"})
    assert r.status_code == 200
    assert r.data == {
        "platform": "android",
        "latest_version": "1.4.0",
        "force_update": True,
        "is_maintenance": False,
        "store_url": "https://play.google.com/x",
        "title": "Yangi versiya chiqdi",
        "subtitle": "Xatolar tuzatildi.",
    }


def test_version_title_and_subtitle_default_to_empty_so_the_app_uses_its_own_text():
    from rest_framework.test import APIClient

    AppRelease.objects.create(platform="ios", latest_version="1.3.0")
    r = APIClient().get(URL, {"platform": "ios"})
    assert r.data["title"] == ""
    assert r.data["subtitle"] == ""


def test_version_requires_a_known_platform():
    from rest_framework.test import APIClient

    for query in ({}, {"platform": "windows"}):
        r = APIClient().get(URL, query)
        assert r.status_code == 400
        assert "error" in r.data


def test_version_of_unpublished_platform_is_404():
    from rest_framework.test import APIClient

    r = APIClient().get(URL, {"platform": "ios"})
    assert r.status_code == 404
    assert r.data["error"]["code"] == "release_not_found"


def test_version_ignores_a_stale_bearer_token():
    from rest_framework.test import APIClient

    AppRelease.objects.create(platform="ios", latest_version="2.0")
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION="Bearer expired-or-garbage")
    assert client.get(URL, {"platform": "ios"}).status_code == 200


@pytest.mark.parametrize("value", ["1", "1.2.3.4.5", "v1.2", "1.2-beta", "", "1..2"])
def test_version_format_rejects_non_numeric_forms(value):
    with pytest.raises(ValidationError):
        validate_version(value)


@pytest.mark.parametrize("value", ["1.0", "1.2.3", "10.20.30.40"])
def test_version_format_accepts_dotted_numbers(value):
    validate_version(value)


def test_maintenance_flag_defaults_to_off_and_is_published_per_platform():
    from rest_framework.test import APIClient

    AppRelease.objects.create(platform="ios", latest_version="1.0.0", is_maintenance=True)
    AppRelease.objects.create(platform="android", latest_version="1.0.0")
    assert APIClient().get(URL, {"platform": "ios"}).data["is_maintenance"] is True
    assert APIClient().get(URL, {"platform": "android"}).data["is_maintenance"] is False
