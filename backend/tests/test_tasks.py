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
    assert create(client_user, agreed_value="100.00").status_code == 403


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


def test_failed_needs_reason_and_authority(owner, worker):
    t = make_task(owner, [worker.pk])
    assert move(worker, t, "FAILED", reason="no").status_code == 403
    assert move(owner, t, "FAILED").status_code == 400
    r = move(owner, t, "FAILED", reason="Client unreachable")
    assert r.data["status"] == "FAILED" and r.data["failure_reason"] == "Client unreachable"


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
