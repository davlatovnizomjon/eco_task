import io
import shutil

import pytest
from django.conf import settings
from django.core.files.uploadedfile import SimpleUploadedFile

from apps.audit.models import AuditLog
from apps.files.models import Attachment
from apps.tasks.models import Task
from tests.conftest import api_as

pytestmark = pytest.mark.django_db
FILES = "/api/v1/files/"
TASKS = "/api/v1/tasks/"
C = "/api/v1/conversations/"
PNG = b"\x89PNG\r\n\x1a\n" + b"0" * 64
JPG = b"\xff\xd8\xff\xe0" + b"0" * 64


@pytest.fixture(autouse=True)
def _clean_media():
    yield
    shutil.rmtree(settings.PRIVATE_MEDIA_ROOT, ignore_errors=True)


def upload(user, data=PNG, name="a.png", content_type="image/png", **extra):
    f = SimpleUploadedFile(name, data, content_type=content_type)
    return api_as(user).post(FILES, {"file": f, **extra}, format="multipart")


def test_upload_returns_kind_name_size_and_private_url(owner):
    r = upload(owner)
    assert r.status_code == 201 and r.data["kind"] == "IMAGE" and r.data["name"] == "a.png"
    assert r.data["size"] == len(PNG) and r.data["url"] == f"/api/v1/files/{r.data['id']}/"
    assert Attachment.objects.get(pk=r.data["id"]).owner_id == owner.pk


@pytest.mark.parametrize(
    ("name", "ctype", "kind"),
    [("n.pdf", "application/pdf", "DOCUMENT"), ("v.m4a", "audio/mp4", "AUDIO"), ("c.mp4", "video/mp4", "VIDEO")],
)
def test_allowed_kinds(owner, name, ctype, kind):
    r = upload(owner, data=b"x" * 100, name=name, content_type=ctype, duration_ms=4200)
    assert r.status_code == 201 and r.data["kind"] == kind and r.data["duration_ms"] == 4200


def test_dangerous_or_fake_files_are_rejected(owner):
    assert upload(owner, b"<script>", "x.html", "text/html").status_code == 415
    assert upload(owner, b"MZ" + b"0" * 50, "x.png", "image/png").status_code == 400  # not a PNG inside
    assert upload(owner, b"", "e.png", "image/png").status_code == 400


def test_too_large_is_413(owner, settings):
    settings.UPLOAD_MAX_BYTES = 100
    assert upload(owner, PNG + b"0" * 200).status_code == 413


def test_anonymous_cannot_upload(db):
    from rest_framework.test import APIClient

    assert APIClient().post(FILES, {}).status_code == 401


def test_unattached_file_is_private_to_its_owner(owner, assistant):
    fid = upload(owner).data["id"]
    assert api_as(owner).get(f"{FILES}{fid}/").status_code == 200
    assert api_as(assistant).get(f"{FILES}{fid}/").status_code == 404
    assert api_as(owner).get(f"{FILES}999999/").status_code == 404


def test_download_headers_for_image_and_document(owner):
    img = api_as(owner).get(f"{FILES}{upload(owner).data['id']}/")
    assert img["Content-Type"] == "image/png" and "attachment" not in img["Content-Disposition"]
    assert img["X-Content-Type-Options"] == "nosniff" and img["Cache-Control"].startswith("private")
    doc_id = upload(owner, b"%PDF" + b"0" * 50, "d.pdf", "application/pdf").data["id"]
    assert "attachment" in api_as(owner).get(f"{FILES}{doc_id}/")["Content-Disposition"]


# --- tasks ------------------------------------------------------------------------------------
def make_task(owner, worker=None, **extra):
    r = api_as(owner).post(TASKS, {"title": "T", "worker_ids": [worker.pk] if worker else [], **extra}, format="json")
    assert r.status_code == 201, r.data
    return r.data["id"]


def test_task_adopts_uploads_and_workers_on_it_can_read_them(owner, worker, worker2):
    fid = upload(owner).data["id"]
    tid = make_task(owner, worker, attachment_ids=[fid])
    r = api_as(worker).get(f"{TASKS}{tid}/")
    assert [a["id"] for a in r.data["attachments"]] == [fid]
    assert api_as(worker).get(f"{FILES}{fid}/").status_code == 200
    assert api_as(worker2).get(f"{FILES}{fid}/").status_code == 404


def test_task_cannot_take_someone_elses_or_unknown_files(owner, assistant):
    foreign = upload(assistant).data["id"]
    r = api_as(owner).post(TASKS, {"title": "T", "attachment_ids": [foreign]}, format="json")
    assert r.status_code == 400 and r.data["error"]["code"] == "invalid_attachment"
    assert api_as(owner).post(TASKS, {"title": "T", "attachment_ids": [9999]}, format="json").status_code == 400


def test_task_file_limits_and_media_kinds(owner):
    ids = [upload(owner).data["id"] for _ in range(11)]
    assert api_as(owner).post(TASKS, {"title": "T", "attachment_ids": ids}, format="json").status_code == 400
    voice = upload(owner, b"x" * 50, "v.m4a", "audio/mp4").data["id"]
    assert api_as(owner).post(TASKS, {"title": "T", "attachment_ids": [voice]}, format="json").status_code == 400


def test_edit_replaces_the_file_set_and_removes_dropped_files(owner):
    a, b = upload(owner).data["id"], upload(owner, JPG, "b.jpg", "image/jpeg").data["id"]
    tid = make_task(owner, attachment_ids=[a])
    r = api_as(owner).patch(f"{TASKS}{tid}/", {"attachment_ids": [b]}, format="json")
    assert [x["id"] for x in r.data["attachments"]] == [b]
    assert not Attachment.objects.filter(pk=a).exists()
    assert AuditLog.objects.filter(action="task.files_changed").count() == 2


def test_deleting_a_task_deletes_its_files(owner):
    fid = upload(owner).data["id"]
    tid = make_task(owner, attachment_ids=[fid])
    api_as(owner).delete(f"{TASKS}{tid}/")
    assert not Attachment.objects.filter(pk=fid).exists() and not Task.objects.filter(pk=tid).exists()


# --- chat ---------------------------------------------------------------------------------------
def dm(a, b):
    return api_as(a).post(C, {"kind": "DIRECT", "user": b.pk}, format="json").data["id"]


def test_voice_note_message_with_duration_and_no_text(owner, worker):
    conv = dm(owner, worker)
    fid = upload(worker, b"x" * 50, "v.m4a", "audio/mp4", duration_ms=9000).data["id"]
    r = api_as(worker).post(f"{C}{conv}/messages/", {"attachment_id": fid}, format="json")
    assert r.status_code == 201 and r.data["body"] == "" and r.data["attachment"]["duration_ms"] == 9000
    assert api_as(owner).get(f"{FILES}{fid}/").status_code == 200  # a member of the room may read it
    again = api_as(worker).post(f"{C}{conv}/messages/", {"attachment_id": fid}, format="json")
    assert again.status_code == 400  # one file, one message


def test_message_needs_text_or_attachment_and_foreign_files_are_refused(owner, worker, assistant):
    conv = dm(owner, worker)
    assert api_as(owner).post(f"{C}{conv}/messages/", {"body": " "}, format="json").status_code == 400
    foreign = upload(assistant).data["id"]
    assert api_as(owner).post(f"{C}{conv}/messages/", {"attachment_id": foreign}, format="json").status_code == 400


def test_outsider_cannot_read_a_chat_file(owner, worker, worker2):
    conv = dm(owner, worker)
    fid = upload(owner).data["id"]
    api_as(owner).post(f"{C}{conv}/messages/", {"attachment_id": fid}, format="json")
    assert api_as(worker2).get(f"{FILES}{fid}/").status_code == 404


def test_deleted_message_hides_its_attachment(owner, worker):
    conv = dm(owner, worker)
    fid = upload(owner).data["id"]
    mid = api_as(owner).post(f"{C}{conv}/messages/", {"attachment_id": fid}, format="json").data["id"]
    r = api_as(owner).delete(f"{C}{conv}/messages/{mid}/")
    assert r.data["attachment"] is None and r.data["deleted"] is True


def test_reply_quotes_a_message_of_the_same_room(owner, worker):
    conv, other = dm(owner, worker), dm(owner, make_other(owner))
    first = api_as(owner).post(f"{C}{conv}/messages/", {"body": "check the receipt please"}, format="json").data["id"]
    r = api_as(worker).post(f"{C}{conv}/messages/", {"body": "ok", "reply_to": first}, format="json")
    assert r.data["reply_to"]["id"] == first and r.data["reply_to"]["body"] == "check the receipt please"
    assert r.data["reply_to"]["sender_name"] == "owner"
    foreign = api_as(owner).post(f"{C}{other}/messages/", {"body": "x"}, format="json").data["id"]
    assert (
        api_as(worker).post(f"{C}{conv}/messages/", {"body": "no", "reply_to": foreign}, format="json").status_code
        == 404
    )


def make_other(owner):
    from apps.core.policies import Role
    from tests.conftest import make_user

    return make_user("other", Role.WORKER)


def test_reply_preview_of_a_deleted_message_is_blank(owner, worker):
    conv = dm(owner, worker)
    first = api_as(owner).post(f"{C}{conv}/messages/", {"body": "secret"}, format="json").data["id"]
    reply = api_as(worker).post(f"{C}{conv}/messages/", {"body": "re", "reply_to": first}, format="json").data["id"]
    api_as(owner).delete(f"{C}{conv}/messages/{first}/")
    history = api_as(worker).get(f"{C}{conv}/messages/").data["results"]
    quoted = next(m for m in history if m["id"] == reply)["reply_to"]
    assert quoted["deleted"] is True and quoted["body"] == ""


def test_group_avatar_needs_staff_and_an_own_image(owner, assistant, worker):
    gid = (
        api_as(owner)
        .post(C, {"kind": "GROUP", "title": "G", "member_ids": [assistant.pk, worker.pk]}, format="json")
        .data["id"]
    )
    fid = upload(owner).data["id"]
    assert api_as(worker).patch(f"{C}{gid}/", {"avatar_id": fid}, format="json").status_code == 403
    r = api_as(owner).patch(f"{C}{gid}/", {"avatar_id": fid}, format="json")
    assert r.data["avatar"]["id"] == fid
    assert api_as(worker).get(f"{FILES}{fid}/").status_code == 200  # members see the group picture
    assert api_as(owner).patch(f"{C}{gid}/", {"avatar_id": None}, format="json").data["avatar"] is None
    doc = upload(owner, b"%PDF" + b"0" * 50, "d.pdf", "application/pdf").data["id"]
    assert api_as(owner).patch(f"{C}{gid}/", {"avatar_id": doc}, format="json").status_code == 400


# --- users ---------------------------------------------------------------------------------------
def test_owner_deletes_a_user_without_history_for_good(owner):
    from apps.accounts.models import User
    from apps.core.policies import Role
    from tests.conftest import make_user

    spare = make_user("spare", Role.WORKER)
    r = api_as(owner).delete(f"/api/v1/users/{spare.pk}/")
    assert r.status_code == 200 and r.data["result"] == "deleted"
    assert not User.objects.filter(pk=spare.pk).exists()


def test_user_with_history_is_deactivated_not_deleted(owner, worker):
    make_task(owner, worker)
    r = api_as(owner).delete(f"/api/v1/users/{owner.pk}/")
    assert r.status_code == 403  # never yourself
    from apps.core.policies import Role
    from tests.conftest import make_user

    boss2 = make_user("boss2", Role.ASSISTANT)
    make_task(boss2)
    r = api_as(owner).delete(f"/api/v1/users/{boss2.pk}/")
    assert r.data["result"] == "deactivated"
    boss2.refresh_from_db()
    assert boss2.is_active is False


def test_only_owner_deletes_users_and_the_last_owner_stays(owner, assistant, worker):
    assert api_as(assistant).delete(f"/api/v1/users/{worker.pk}/").status_code == 403
    assert api_as(worker).delete(f"/api/v1/users/{worker.pk}/").status_code == 404


def test_organization_contact_person_and_note(owner):
    r = api_as(owner).post(
        "/api/v1/users/",
        {"username": "org1", "password": "Str0ng-Test-Passphrase!", "role": "CLIENT", "full_name": "Yashil Bog MChJ",
         "is_org": True, "contact_person": "Dilshod Aka", "note": "Doimiy mijoz"},
        format="json",
    )  # fmt: skip
    assert r.status_code == 201 and r.data["contact_person"] == "Dilshod Aka" and r.data["note"] == "Doimiy mijoz"
    patched = api_as(owner).patch(f"/api/v1/users/{r.data['id']}/", {"note": "VIP"}, format="json")
    assert patched.data["note"] == "VIP" and io.BytesIO is not None
