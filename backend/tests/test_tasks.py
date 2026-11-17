import pytest
from django.db import IntegrityError, transaction

from apps.audit.models import AuditLog
from apps.projects.models import Project
from apps.tasks.models import Status, Task, TaskAssignment, TaskHistory
from tests.conftest import api_as

pytestmark = pytest.mark.django_db
URL = "/api/v1/tasks/"


def create(user, **extra):
    return api_as(user).post(URL, {"title": "Plant roses", **extra}, format="json")


def make_task(owner, worker_ids=(), **extra):
    r = create(owner, worker_ids=list(worker_ids), **extra)
    assert r.status_code == 201, r.data
    return r.data["id"]


def move(user, task_id, to, **extra):
    return api_as(user).post(f"{URL}{task_id}/transition/", {"to_status": to, **extra}, format="json")


# --- creation -----------------------------------------------------------------------------
def test_worker_cannot_create_tasks(worker):
    assert create(worker).status_code == 403
    assert not Task.objects.exists()


def test_owner_and_assistant_create_open_task_with_history(owner, assistant):
    for user in (owner, assistant):
        r = create(user)
        assert r.status_code == 201 and r.data["status"] == "OPEN" and r.data["creator"]["id"] == user.pk
    assert TaskHistory.objects.filter(from_status="", to_status="OPEN").count() == 2
    assert AuditLog.objects.filter(action="task.created").count() == 2


def test_status_cannot_be_set_on_create_or_patch(owner):
    r = create(owner, status="COMPLETED")
    assert r.data["status"] == "OPEN"
    patched = api_as(owner).patch(f"{URL}{r.data['id']}/", {"status": "COMPLETED"}, format="json")
    assert patched.data["status"] == "OPEN"


def test_client_creates_only_for_self(client_user, client2, worker):
    r = create(client_user, client=client2.pk)
    assert r.status_code == 201 and r.data["client"]["id"] == client_user.pk
    assert create(client_user, worker_ids=[worker.pk]).status_code == 403


def test_client_gives_a_budget_for_their_own_order(client_user):
    r = create(client_user, agreed_value="100.00")
    assert r.status_code == 201 and r.data["agreed_value"] == "100.00"


def test_client_edits_and_deletes_only_their_own_open_order(owner, client_user, client2, worker):
    mine = create(client_user).data["id"]
    r = api_as(client_user).patch(f"{URL}{mine}/", {"title": "Renamed", "address": "Yunusobod"}, format="json")
    assert r.status_code == 200 and r.data["title"] == "Renamed"
    assert api_as(client_user).patch(f"{URL}{mine}/", {"priority": "HIGH"}, format="json").status_code == 403
    assert api_as(client2).patch(f"{URL}{mine}/", {"title": "x"}, format="json").status_code == 404
    theirs = make_task(owner, [worker.pk], client=client_user.pk)  # created by staff for the client
    assert api_as(client_user).patch(f"{URL}{theirs}/", {"title": "x"}, format="json").status_code == 403
    assert api_as(client_user).delete(f"{URL}{theirs}/").status_code == 403
    started = create(client_user).data["id"]
    Task.objects.filter(pk=started).update(status=Status.IN_PROGRESS)
    assert api_as(client_user).patch(f"{URL}{started}/", {"title": "x"}, format="json").status_code == 403
    assert api_as(client_user).delete(f"{URL}{started}/").status_code == 403
    assert api_as(client_user).delete(f"{URL}{mine}/").status_code == 204
    assert not Task.objects.filter(pk=mine).exists()


def test_client_cannot_use_foreign_project(client_user, client2, owner):
    project = Project.objects.create(name="Other", client=client2, created_by=owner)
    assert create(client_user, project=project.pk).status_code == 404


def test_agreed_value_requires_finance_capability(owner, assistant):
    assert create(assistant, agreed_value="500.00").status_code == 403
    r = create(owner, agreed_value="500.00")
    assert r.status_code == 201 and r.data["agreed_value"] == "500.00"


def test_negative_value_and_bad_dates_rejected(owner):
    assert create(owner, agreed_value="-1").status_code == 400
    assert create(owner, start_date="2026-02-01", due_date="2026-01-01").status_code == 400


# --- visibility / IDOR --------------------------------------------------------------------
def test_visibility_matrix(owner, assistant, worker, worker2, client_user, client2):
    t = make_task(owner, [worker.pk], client=client_user.pk)
    assert api_as(owner).get(f"{URL}{t}/").status_code == 200
    assert api_as(assistant).get(f"{URL}{t}/").status_code == 200
    assert api_as(worker).get(f"{URL}{t}/").status_code == 200
    assert api_as(client_user).get(f"{URL}{t}/").status_code == 200
    assert api_as(worker2).get(f"{URL}{t}/").status_code == 404
    assert api_as(client2).get(f"{URL}{t}/").status_code == 404
    assert api_as(client2).get(URL).data["count"] == 0
    assert api_as(worker2).get(URL).data["count"] == 0
    assert api_as(worker).get(URL).data["count"] == 1


def test_foreign_user_cannot_modify_via_id_guess(owner, worker, worker2):
    t = make_task(owner, [worker.pk])
    assert move(worker2, t, "IN_PROGRESS").status_code == 404
    assert api_as(worker2).put(f"{URL}{t}/assignees/", {"worker_ids": [worker2.pk]}, format="json").status_code == 404
    assert api_as(worker2).post(f"{URL}{t}/comments/", {"body": "hi"}, format="json").status_code == 404


def test_money_hidden_from_workers_and_assistants_visible_to_client(owner, assistant, worker, client_user):
    t = make_task(owner, [worker.pk], client=client_user.pk, agreed_value="900.00")
    assert "agreed_value" not in api_as(worker).get(f"{URL}{t}/").data
    assert "agreed_value" not in api_as(assistant).get(f"{URL}{t}/").data
    assert api_as(client_user).get(f"{URL}{t}/").data["agreed_value"] == "900.00"
    assert api_as(owner).get(f"{URL}{t}/").data["agreed_value"] == "900.00"


# --- assignments --------------------------------------------------------------------------
def test_multi_worker_assignment_and_reassignment_keeps_history(owner, assistant, worker, worker2):
    t = make_task(assistant, [worker.pk, worker2.pk])
    assert {a["id"] for a in api_as(owner).get(f"{URL}{t}/").data["assignees"]} == {worker.pk, worker2.pk}
    r = api_as(assistant).put(f"{URL}{t}/assignees/", {"worker_ids": [worker2.pk]}, format="json")
    assert [a["id"] for a in r.data["assignees"]] == [worker2.pk]
    assert TaskAssignment.objects.filter(task_id=t).count() == 2  # closed row kept
    assert api_as(worker).get(f"{URL}{t}/").status_code == 404  # removed worker loses access


def test_only_active_workers_can_be_assigned(owner, assistant, client_user, worker):
    t = make_task(owner)
    for bad in ([client_user.pk], [assistant.pk], [999999]):
        assert api_as(owner).put(f"{URL}{t}/assignees/", {"worker_ids": bad}, format="json").status_code == 400
    assert api_as(worker).put(f"{URL}{t}/assignees/", {"worker_ids": [worker.pk]}, format="json").status_code == 404


def test_duplicate_active_assignment_blocked_by_database(owner, worker):
    task = Task.objects.get(pk=make_task(owner, [worker.pk]))
    with pytest.raises(IntegrityError), transaction.atomic():
        TaskAssignment.objects.create(task=task, worker=worker)


# --- transitions --------------------------------------------------------------------------
def test_full_happy_path_with_approval(owner, assistant, worker):
    t = make_task(owner, [worker.pk])
    assert move(worker, t, "IN_PROGRESS").data["status"] == "IN_PROGRESS"
    assert move(worker, t, "COMPLETED").status_code == 403  # approval required
    assert move(worker, t, "REVIEW").data["status"] == "REVIEW"
    r = move(assistant, t, "COMPLETED")
    assert r.data["status"] == "COMPLETED" and r.data["completed_at"] and r.data["approved_by"] == assistant.pk
    assert [h["to_status"] for h in api_as(owner).get(f"{URL}{t}/history/").data] == [
        "OPEN", "IN_PROGRESS", "REVIEW", "COMPLETED",
    ]  # fmt: skip


def test_worker_completes_directly_when_approval_disabled(owner, worker, settings):
    settings.TASK_COMPLETION_REQUIRES_APPROVAL = False
    t = make_task(owner, [worker.pk])
    move(worker, t, "IN_PROGRESS")
    assert move(worker, t, "COMPLETED").status_code == 200


def test_return_for_rework_requires_reason(owner, worker):
    t = make_task(owner, [worker.pk])
    move(worker, t, "IN_PROGRESS")
    move(worker, t, "REVIEW")
    assert move(owner, t, "IN_PROGRESS").status_code == 400
    assert move(owner, t, "IN_PROGRESS", reason="Photos missing").status_code == 200


@pytest.mark.parametrize(
    "src,dst", [("OPEN", "COMPLETED"), ("OPEN", "REVIEW"), ("COMPLETED", "OPEN"), ("FAILED", "IN_PROGRESS")]
)
def test_invalid_transitions_rejected(owner, src, dst):
    task = Task.objects.get(pk=make_task(owner))
    kwargs = {"status": src}
    if src == "COMPLETED":
        from django.utils import timezone

        kwargs["completed_at"] = timezone.now()
    if src == "FAILED":
        kwargs["failure_reason"] = "x"
    Task.objects.filter(pk=task.pk).update(**kwargs)
    assert move(owner, task.pk, dst, reason="r").status_code == 409


def test_failed_needs_reason_and_authority(owner, worker, worker2, client_user):
    t = make_task(owner, [worker.pk])
    assert move(owner, t, "FAILED").status_code == 400
    assert move(worker, t, "FAILED").status_code == 400  # the assigned worker needs a reason too
    assert move(worker2, t, "FAILED", reason="no").status_code == 404  # not their task
    assert move(client_user, t, "FAILED", reason="no").status_code == 404
    r = move(owner, t, "FAILED", reason="Client unreachable")
    assert r.data["status"] == "FAILED" and r.data["failure_reason"] == "Client unreachable"


def test_assigned_worker_reports_a_task_they_could_not_do(owner, worker):
    t = make_task(owner, [worker.pk])
    r = move(worker, t, "FAILED", reason="Gate was locked")
    assert r.status_code == 200 and r.data["status"] == "FAILED" and r.data["failure_reason"] == "Gate was locked"
    t2 = make_task(owner, [worker.pk])
    assert move(worker, t2, "IN_PROGRESS").status_code == 200
    assert move(worker, t2, "REVIEW").status_code == 200
    assert move(worker, t2, "FAILED", reason="late").status_code == 403  # in review only a manager decides


def test_unassigned_worker_cannot_progress_and_client_cannot_start(owner, worker, worker2, client_user):
    t = make_task(owner, [worker.pk], client=client_user.pk)
    assert move(worker2, t, "IN_PROGRESS").status_code == 404
    assert move(client_user, t, "IN_PROGRESS").status_code == 403


def test_client_cancels_own_open_task_only(owner, client_user, worker):
    t = create(client_user).data["id"]
    assert move(client_user, t, "CANCELED").status_code == 200
    t2 = make_task(owner, [worker.pk], client=client_user.pk)
    move(worker, t2, "IN_PROGRESS")
    assert move(client_user, t2, "CANCELED").status_code == 403


def test_stale_version_conflicts(owner, worker):
    t = make_task(owner, [worker.pk])
    assert move(worker, t, "IN_PROGRESS", version=1).status_code == 200
    assert move(owner, t, "FAILED", reason="x", version=1).status_code == 409
    assert api_as(owner).patch(f"{URL}{t}/", {"title": "new", "version": 1}, format="json").status_code == 409
    assert api_as(owner).patch(f"{URL}{t}/", {"title": "new", "version": 2}, format="json").status_code == 200


def test_closed_task_is_immutable(owner, worker):
    t = make_task(owner, [worker.pk])
    move(owner, t, "CANCELED")
    assert api_as(owner).patch(f"{URL}{t}/", {"title": "x"}, format="json").status_code == 409
    assert api_as(owner).put(f"{URL}{t}/assignees/", {"worker_ids": []}, format="json").status_code == 409


def test_database_constraints_guard_inconsistent_rows(owner):
    task = Task.objects.get(pk=make_task(owner))
    for bad in ({"status": "FAILED"}, {"status": "BOGUS"}, {"completed_at": task.created_at}, {"agreed_value": -5}):
        with pytest.raises(IntegrityError), transaction.atomic():
            Task.objects.filter(pk=task.pk).update(**bad)


# --- comments, filters, pagination --------------------------------------------------------
def test_internal_comments_hidden_from_clients(owner, worker, client_user):
    t = make_task(owner, [worker.pk], client=client_user.pk)
    api_as(worker).post(f"{URL}{t}/comments/", {"body": "secret note", "is_internal": True}, format="json")
    api_as(client_user).post(f"{URL}{t}/comments/", {"body": "hello", "is_internal": True}, format="json")
    assert [c["body"] for c in api_as(client_user).get(f"{URL}{t}/comments/").data] == ["hello"]
    assert len(api_as(owner).get(f"{URL}{t}/comments/").data) == 2


def test_filters_search_pagination_and_no_duplicates(owner, worker, worker2):
    for i in range(25):
        make_task(owner, [worker.pk, worker2.pk], title=f"Task {i}", priority="HIGH" if i % 2 else "LOW")
    r = api_as(owner).get(URL, {"worker": worker.pk})
    assert r.data["count"] == 25 and len(r.data["results"]) == 20  # two workers, still one row per task
    assert api_as(owner).get(URL, {"priority": "HIGH"}).data["count"] == 12
    assert api_as(owner).get(URL, {"q": "Task 7"}).data["count"] == 1
    assert api_as(owner).get(URL, {"page_size": 1000}).data["results"].__len__() == 25
    assert api_as(owner).get(URL, {"ordering": "bogus;drop"}).status_code == 200


def test_task_status_enum_matches_model():
    assert {s.value for s in Status} == {"OPEN", "IN_PROGRESS", "REVIEW", "COMPLETED", "FAILED", "CANCELED"}


# --- wizard fields, delete and personal tasks (new design) ---------------------------------
def test_task_keeps_client_name_address_currency_and_reminder(owner):
    r = create(
        owner,
        client_name="Yashil Bog MChJ",
        client_is_org=True,
        address="Yunusobod, Amir Temur 108",
        currency="USD",
        agreed_value="1200",
        remind_at="2026-10-26T13:00:00Z",
    )
    assert r.status_code == 201
    assert r.data["client_name"] == "Yashil Bog MChJ" and r.data["client_is_org"] is True
    assert r.data["address"] == "Yunusobod, Amir Temur 108" and r.data["currency"] == "USD"
    assert r.data["remind_at"].startswith("2026-10-26T13:00")


def test_unknown_currency_is_rejected(owner):
    assert create(owner, currency="EUR").status_code == 400


def test_staff_can_edit_the_new_fields_but_workers_cannot(owner, worker):
    task_id = make_task(owner, [worker.pk])
    r = api_as(owner).patch(f"{URL}{task_id}/", {"address": "Chilonzor", "currency": "USD"}, format="json")
    assert r.status_code == 200 and r.data["address"] == "Chilonzor" and r.data["currency"] == "USD"
    assert api_as(worker).patch(f"{URL}{task_id}/", {"address": "x"}, format="json").status_code == 403


def test_currency_is_hidden_with_the_price_from_workers(owner, worker):
    task_id = make_task(owner, [worker.pk], agreed_value="500", currency="USD")
    data = api_as(worker).get(f"{URL}{task_id}/").data
    assert "agreed_value" not in data and "currency" not in data


def test_owner_and_assistant_delete_any_task_and_it_is_audited(owner, assistant, worker):
    for actor, creator in ((owner, owner), (assistant, assistant), (assistant, owner), (owner, assistant)):
        task_id = make_task(creator, [worker.pk])
        assert api_as(actor).delete(f"{URL}{task_id}/").status_code == 204
        assert not Task.objects.filter(pk=task_id).exists()
        assert AuditLog.objects.filter(action="task.deleted", target_id=task_id, actor=actor).exists()
        assert api_as(actor).get(f"{URL}{task_id}/").status_code == 404


def test_worker_and_client_cannot_delete_tasks(owner, worker, client_user):
    task_id = make_task(owner, [worker.pk])
    assert api_as(worker).delete(f"{URL}{task_id}/").status_code == 403
    assert api_as(client_user).delete(f"{URL}{task_id}/").status_code in (403, 404)
    assert Task.objects.filter(pk=task_id).exists()


def test_delete_of_an_invisible_task_is_404_not_403(owner, worker, worker2):
    task_id = make_task(owner, [worker.pk])
    assert api_as(worker2).delete(f"{URL}{task_id}/").status_code == 404


def test_manager_completes_an_own_open_task_in_two_steps(assistant):
    task_id = make_task(assistant)
    assert move(assistant, task_id, "COMPLETED").status_code == 409  # the machine has no OPEN -> COMPLETED move
    assert move(assistant, task_id, "IN_PROGRESS").status_code == 200
    r = move(assistant, task_id, "COMPLETED")
    assert r.status_code == 200 and r.data["status"] == "COMPLETED" and r.data["completed_at"]


def test_author_and_staff_delete_comments_others_cannot(owner, assistant, worker, worker2):
    task_id = make_task(owner, [worker.pk, worker2.pk])
    mine = api_as(worker).post(f"{URL}{task_id}/comments/", {"body": "note"}, format="json").data["id"]
    other = api_as(worker2).post(f"{URL}{task_id}/comments/", {"body": "mine too"}, format="json").data["id"]
    assert api_as(worker).delete(f"{URL}{task_id}/comments/{other}/").status_code == 403
    assert api_as(worker).delete(f"{URL}{task_id}/comments/{mine}/").status_code == 204
    assert api_as(assistant).delete(f"{URL}{task_id}/comments/{other}/").status_code == 204
    assert api_as(owner).delete(f"{URL}{task_id}/comments/999999/").status_code == 404


def test_comment_of_a_foreign_task_is_404(owner, worker, worker2):
    task_id = make_task(owner, [worker.pk])
    comment = api_as(worker).post(f"{URL}{task_id}/comments/", {"body": "n"}, format="json").data["id"]
    assert api_as(worker2).delete(f"{URL}{task_id}/comments/{comment}/").status_code == 404
