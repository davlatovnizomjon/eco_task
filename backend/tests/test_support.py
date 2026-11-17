import pytest
from django.core.exceptions import ValidationError
from rest_framework.test import APIClient

from apps.support.models import SupportContact, validate_phone, validate_telegram

pytestmark = pytest.mark.django_db

URL = "/api/v1/support/"


def test_contacts_are_public_and_have_the_documented_shape():
    SupportContact.objects.all().delete()
    SupportContact.objects.create(phone="+998 71 200 00 00", telegram="eco_tasks_bot")
    r = APIClient().get(URL)
    assert r.status_code == 200
    assert set(r.data) == {"phone", "telegram"}
    assert r.data["phone"] == "+998 71 200 00 00"
    assert r.data["telegram"] == "@eco_tasks_bot"


def test_first_deploy_publishes_the_seeded_contacts():
    assert APIClient().get(URL).data["telegram"] == "@eco_tasks_bot"


def test_unpublished_contacts_are_404():
    SupportContact.objects.all().delete()
    r = APIClient().get(URL)
    assert r.status_code == 404
    assert r.data["error"]["code"] == "support_not_found"


def test_stale_bearer_token_is_ignored():
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION="Bearer expired-or-garbage")
    assert client.get(URL).status_code == 200


def test_only_one_row_can_exist():
    SupportContact.objects.create(phone="+998 90 111 22 33", telegram="@other_bot")
    assert SupportContact.objects.count() == 1


@pytest.mark.parametrize("value", ["", "abc", "12", "+99-"])
def test_phone_rejects_garbage(value):
    with pytest.raises(ValidationError):
        validate_phone(value)


@pytest.mark.parametrize("value", ["@ab", "1bot", "has space", ""])
def test_telegram_rejects_garbage(value):
    with pytest.raises(ValidationError):
        validate_telegram(value)
