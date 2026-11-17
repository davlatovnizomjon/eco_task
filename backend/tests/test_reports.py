from datetime import timedelta

import pytest
from django.utils import timezone

from apps.accounts.models import User
from apps.core.policies import Role
from apps.reports import services
from apps.tasks.models import Status, Task
from tests.conftest import api_as, make_user

pytestmark = pytest.mark.django_db
STATS = "/api/v1/reports/stats/"


def done_task(creator, worker, value=1000, days_ago=0, due_in=1, **extra):
    task = Task.objects.create(
        creator=creator,
        title="Done",
        status=Status.COMPLETED,
        completed_at=timezone.now() - timedelta(days=days_ago),
        due_date=timezone.localdate() + timedelta(days=due_in),
        agreed_value=value,
        **extra,
    )
    if worker:
        task.assignments.create(worker=worker, assigned_by=creator)
    return task


def get(user, **params):
    return api_as(user).get(STATS, params)


# --- windows ------------------------------------------------------------------------------
def test_windows_cover_week_month_year_and_step_back():
    from datetime import date

    today = date(2026, 10, 21)  # a Wednesday
    assert services.window("week", 0, today) == (date(2026, 10, 19), date(2026, 10, 25))
    assert services.window("week", -1, today) == (date(2026, 10, 12), date(2026, 10, 18))
    assert services.window("month", 0, today) == (date(2026, 10, 1), date(2026, 10, 31))
    assert services.window("month", -10, today) == (date(2025, 12, 1), date(2025, 12, 31))
    assert services.window("year", -1, today) == (date(2025, 1, 1), date(2025, 12, 31))


def test_bars_have_one_slot_per_day_part_or_month():
    from datetime import date

    d = date(2026, 10, 21)
    assert len(services.buckets("week", *services.window("week", 0, d))) == 7
    assert len(services.buckets("month", *services.window("month", 0, d))) == 4
    assert len(services.buckets("year", *services.window("year", 0, d))) == 12


# --- access -------------------------------------------------------------------------------
@pytest.mark.parametrize("kind", [k for k in services.KINDS if k not in services.WORKER_KINDS])
def test_worker_gets_403_for_staff_screens(worker, kind):
    assert get(worker, kind=kind).status_code == 403


@pytest.mark.parametrize("kind", services.WORKER_KINDS)
def test_worker_sees_only_own_numbers(owner, worker, worker2, kind):
    done_task(owner, worker)
    done_task(owner, worker2)
    done_task(owner, worker2)
    r = get(worker, kind=kind, period="month")
    assert r.status_code == 200
    if kind == "mine":
        assert r.data["a"] == 1 and r.data["total"] == 1 and r.data["b"] == 0
    else:
        assert r.data["total"] == 1


def test_worker_dashboard_has_own_deadlines_and_no_team(owner, worker, worker2):
    today = timezone.localdate()
    mine = Task.objects.create(creator=owner, title="Mine", status=Status.OPEN, due_date=today)
    mine.assignments.create(worker=worker, assigned_by=owner)
    theirs = Task.objects.create(creator=owner, title="Theirs", status=Status.OPEN, due_date=today)
    theirs.assignments.create(worker=worker2, assigned_by=owner)
    r = api_as(worker).get("/api/v1/reports/dashboard/")
    assert r.status_code == 200 and r.data["team"] == []
    assert [t["title"] for t in r.data["due_today"]] == ["Mine"]


@pytest.mark.parametrize("kind", services.KINDS)
def test_client_gets_403_everywhere(client_user, kind):
    assert get(client_user, kind=kind).status_code == 403
    assert api_as(client_user).get("/api/v1/reports/dashboard/").status_code == 403


@pytest.mark.parametrize("kind", ["finance", "managers"])
def test_assistant_cannot_see_money_screens(assistant, kind):
    assert get(assistant, kind=kind).status_code == 403


@pytest.mark.parametrize("kind", ["tasks", "mine", "clients", "staff"])
def test_assistant_sees_non_money_screens(assistant, kind):
    assert get(assistant, kind=kind).status_code == 200


def test_unknown_kind_future_offset_and_period_are_400(owner):
    assert get(owner, kind="nope").status_code == 400
    assert get(owner, kind="tasks", offset=1).status_code == 400
    assert get(owner, kind="tasks", period="decade").status_code == 400


def test_anonymous_is_401(db):
    from rest_framework.test import APIClient

    assert APIClient().get(STATS, {"kind": "tasks"}).status_code == 401


# --- values -------------------------------------------------------------------------------
def test_tasks_stats_split_adds_up_and_counts_overdue(owner, worker):
    done_task(owner, worker)
    Task.objects.create(creator=owner, title="Open", status=Status.OPEN, due_date=timezone.localdate())
    Task.objects.create(
        creator=owner, title="Late", status=Status.IN_PROGRESS, due_date=timezone.localdate() - timedelta(days=2)
    )
    Task.objects.create(creator=owner, title="Review", status=Status.REVIEW)
    r = get(owner, kind="tasks", period="year").data
    assert r["total"] == 4 and sum(r["split"]) == 4
    assert r["split"] == [1, 2, 1, 0]  # done, in progress (+review), new, closed badly
    assert r["facts"][1] == 1  # overdue
    assert len(r["bars"]) == 12 and sum(r["bars"]) == 1
    assert r["delta"] is None  # nothing in the previous window


def test_finance_sums_only_the_requested_currency(owner, worker):
    done_task(owner, worker, value=1000)
    done_task(owner, worker, value=500)
    done_task(owner, worker, value=70, currency="USD")
    uzs = get(owner, kind="finance", period="year").data
    assert float(uzs["total"]) == 1500 and uzs["a"] == 2 and uzs["b"] == 750
    assert float(uzs["facts"][1]) == 1500
    usd = get(owner, kind="finance", period="year", currency="USD").data
    assert float(usd["total"]) == 70


def test_finance_plan_counts_pending_and_canceled(owner):
    today = timezone.localdate()
    Task.objects.create(creator=owner, title="Planned", status=Status.IN_PROGRESS, due_date=today, agreed_value=800)
    Task.objects.create(creator=owner, title="Gone", status=Status.CANCELED, due_date=today, agreed_value=300)
    r = get(owner, kind="finance", period="year").data
    assert float(r["plan"]) == 800  # canceled work is not planned
    assert r["facts"][2] == 1 and float(r["facts"][3]) == 800  # pending
    assert r["facts"][4] == 1 and float(r["facts"][5]) == 300  # canceled


def test_stats_delta_compares_with_previous_window(owner):
    before = timezone.now() - timedelta(days=370)
    for _ in range(2):
        Task.objects.create(creator=owner, title="Now", status=Status.OPEN)
    old = Task.objects.create(creator=owner, title="Before", status=Status.OPEN)
    Task.objects.filter(pk=old.pk).update(created_at=before)
    assert get(owner, kind="tasks", period="year").data["delta"] == 100  # 2 now vs 1 before
    old2 = Task.objects.create(creator=owner, title="Before 2", status=Status.OPEN)
    Task.objects.filter(pk=old2.pk).update(created_at=before)
    assert get(owner, kind="tasks", period="year").data["delta"] == 0  # 2 vs 2


def test_stats_delta_is_null_without_a_previous_window_baseline(owner):
    Task.objects.create(creator=owner, title="Now", status=Status.OPEN)
    assert get(owner, kind="tasks", period="year").data["delta"] is None


def test_mine_counts_only_my_tasks_and_added_clients(owner, assistant):
    Task.objects.create(creator=owner, title="Mine", status=Status.OPEN)
    Task.objects.create(creator=assistant, title="Theirs", status=Status.OPEN)
    r = get(owner, kind="mine", period="year").data
    assert r["total"] == 1


def test_clients_screen_lists_new_and_all_with_task_counts(owner, client_user, client2):
    User.objects.filter(pk=client2.pk).update(is_org=True)
    Task.objects.create(creator=owner, client=client_user, title="For client", status=Status.OPEN)
    r = get(owner, kind="clients", period="year").data
    assert r["total"] == 2 and r["a"] == 2 and r["b"] == 1
    assert {row["user"]["id"] for row in r["people"]} == {client_user.pk, client2.pk}
    counts = {row["user"]["id"]: row["a"] for row in r["everyone"]}
    assert counts[client_user.pk] == 1 and counts[client2.pk] == 0


def test_staff_ranks_workers_by_done_tasks(owner, worker, worker2):
    done_task(owner, worker)
    done_task(owner, worker)
    done_task(owner, worker2)
    r = get(owner, kind="staff", period="year").data
    assert r["total"] == 2 and r["a"] == 3
    assert [p["user"]["id"] for p in r["people"]] == [worker.pk, worker2.pk]
    assert [p["b"] for p in r["people"]] == [2, 1]


def test_managers_screen_sums_income_per_manager(owner, assistant):
    done_task(assistant, None, value=900)
    r = get(owner, kind="managers", period="year").data
    assert r["total"] == 1 and float(r["b"]) == 900 and r["people"][0]["a"] == 1


def test_empty_window_returns_zeroes_not_errors(owner):
    r = get(owner, kind="tasks", period="week", offset=-5).data
    assert r["total"] == 0 and r["split"] == [0, 0, 0, 0]


# --- export + dashboard -------------------------------------------------------------------
def test_export_is_a_csv_attachment(owner, worker):
    done_task(owner, worker)
    r = api_as(owner).post("/api/v1/reports/export/", {"kind": "tasks", "period": "year"}, format="json")
    assert r.status_code == 200 and r["Content-Type"].startswith("text/csv")
    assert "attachment" in r["Content-Disposition"] and r.content.decode().startswith("metric,value")


def test_export_respects_finance_cap(assistant):
    r = api_as(assistant).post("/api/v1/reports/export/", {"kind": "finance"}, format="json")
    assert r.status_code == 403


def test_dashboard_counts_waiting_tasks_by_creator_kind(owner, client_user, worker):
    Task.objects.create(creator=owner, title="Staff made", status=Status.OPEN)
    Task.objects.create(creator=client_user, client=client_user, title="Client made", status=Status.OPEN)
    Task.objects.create(creator=owner, title="Review", status=Status.REVIEW)
    r = api_as(owner).get("/api/v1/reports/dashboard/")
    assert r.status_code == 200
    assert (r.data["pending_new"], r.data["pending_client"], r.data["in_review"]) == (1, 1, 1)


def test_dashboard_lists_today_and_overdue_tasks_soonest_first(owner):
    today = timezone.localdate()
    Task.objects.create(creator=owner, title="Today", status=Status.OPEN, due_date=today)
    Task.objects.create(creator=owner, title="Late", status=Status.OPEN, due_date=today - timedelta(days=1))
    Task.objects.create(creator=owner, title="Later", status=Status.OPEN, due_date=today + timedelta(days=3))
    r = api_as(owner).get("/api/v1/reports/dashboard/")
    assert [t["title"] for t in r.data["due_today"]] == ["Late", "Today"]
    assert r.data["overdue"] == 1


def test_dashboard_forbidden_for_worker(worker):
    assert api_as(worker).get("/api/v1/reports/dashboard/").status_code == 403


def test_assistant_dashboard_is_scoped_by_visible_tasks(assistant, owner):
    Task.objects.create(creator=owner, title="Any", status=Status.OPEN)
    assert api_as(assistant).get("/api/v1/reports/dashboard/").data["pending_new"] == 1
    make_user("w3", Role.WORKER)
