import pytest
from rest_framework.test import APIClient

from apps.legal.models import LegalDocument

pytestmark = pytest.mark.django_db

TERMS_URL = "/api/v1/legal/terms/"
PRIVACY_URL = "/api/v1/legal/privacy/"


def make(kind, language="uz", title="T", message="M"):
    return LegalDocument.objects.create(kind=kind, language=language, title=title, message=message)


def test_terms_are_public_and_have_the_documented_shape():
    LegalDocument.objects.all().delete()
    make("terms", title="Foydalanish shartlari", message="Rozilik...")
    r = APIClient().get(TERMS_URL)
    assert r.status_code == 200
    assert set(r.data) == {"title", "message", "updated_at"}
    assert r.data["title"] == "Foydalanish shartlari"


def test_privacy_returns_privacy_not_terms():
    LegalDocument.objects.all().delete()
    make("terms", title="Terms")
    make("privacy", title="Privacy")
    assert APIClient().get(PRIVACY_URL).data["title"] == "Privacy"


def test_language_comes_from_the_accept_language_header_with_fallback_to_uzbek():
    LegalDocument.objects.all().delete()
    make("terms", "uz", title="uz-text")
    make("terms", "ru", title="ru-text")
    client = APIClient()
    assert client.get(TERMS_URL, HTTP_ACCEPT_LANGUAGE="ru").data["title"] == "ru-text"
    assert client.get(TERMS_URL, HTTP_ACCEPT_LANGUAGE="ru-RU,ru;q=0.9").data["title"] == "ru-text"
    assert client.get(TERMS_URL, HTTP_ACCEPT_LANGUAGE="uz-Cyrl").data["title"] == "uz-text"  # not published: falls back
    assert client.get(TERMS_URL, HTTP_ACCEPT_LANGUAGE="xx").data["title"] == "uz-text"
    assert client.get(TERMS_URL).data["title"] == "uz-text"


def test_unpublished_document_is_404():
    LegalDocument.objects.all().delete()
    r = APIClient().get(PRIVACY_URL)
    assert r.status_code == 404
    assert r.data["error"]["code"] == "legal_document_not_found"


def test_stale_bearer_token_is_ignored():
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION="Bearer expired-or-garbage")
    assert client.get(TERMS_URL).status_code == 200


def test_every_app_language_has_both_documents_published_by_the_migrations():
    for kind in ("terms", "privacy"):
        for language in ("uz", "uz-Cyrl", "ru"):
            assert LegalDocument.objects.filter(kind=kind, language=language).exists(), (kind, language)
    r = APIClient().get(TERMS_URL, HTTP_ACCEPT_LANGUAGE="ru")
    assert r.data["title"] == "Условия использования"
    assert r.data["message"].startswith("1. ")
