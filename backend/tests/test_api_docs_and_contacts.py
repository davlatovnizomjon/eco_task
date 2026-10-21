import pytest

pytestmark = pytest.mark.django_db


def test_openapi_schema_is_served_with_bearer_scheme(as_user, owner):
    r = as_user(owner).get("/api/schema/?format=json")
    assert r.status_code == 200
    assert "bearerAuth" in r.json()["components"]["securitySchemes"]
    assert "/api/v1/conversations/contacts/" in r.json()["paths"]


def test_contacts_for_worker_are_staff_only(as_user, owner, assistant, worker, worker2, client_user):
    r = as_user(worker).get("/api/v1/conversations/contacts/")
    assert r.status_code == 200
    assert {u["username"] for u in r.data} == {"owner", "assistant"}


def test_contacts_for_staff_include_everyone_but_self(as_user, owner, assistant, worker, client_user):
    r = as_user(assistant).get("/api/v1/conversations/contacts/")
    assert {u["username"] for u in r.data} == {"owner", "worker", "client"}
    assert all("password" not in u for u in r.data)


def test_contacts_search(as_user, owner, worker, client_user):
    r = as_user(owner).get("/api/v1/conversations/contacts/?q=wor")
    assert [u["username"] for u in r.data] == ["worker"]


def test_users_list_filters_by_role_list_and_search(as_user, owner, assistant, worker, client_user):
    c = as_user(owner)
    r = c.get("/api/v1/users/?role=OWNER,ASSISTANT")
    assert {u["username"] for u in r.data["results"]} == {"owner", "assistant"}
    r = c.get("/api/v1/users/?q=cli")
    assert [u["username"] for u in r.data["results"]] == ["client"]


def test_seed_demo_creates_accounts_in_debug_only(settings):
    from django.core.management import call_command
    from django.core.management.base import CommandError

    from apps.accounts.models import User

    settings.DEBUG = False
    with pytest.raises(CommandError):
        call_command("seed_demo")
    settings.DEBUG = True
    call_command("seed_demo")
    call_command("seed_demo")  # idempotent
    assert User.objects.filter(username__in=["jamshid", "malika", "boris", "gulnora"]).count() == 4
