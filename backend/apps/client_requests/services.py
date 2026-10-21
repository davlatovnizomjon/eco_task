"""Request business rules. Every mutation is one transaction that also writes audit and notification rows."""

from django.db import transaction

from apps.accounts.models import User
from apps.audit.services import record
from apps.core.errors import DomainError
from apps.core.policies import Cap, Role, can
from apps.notifications.services import notify

from .models import STATUS_ORDER, RequestMessage, ServiceRequest, Status

EDITABLE_BY_STAFF = {"date", "slot"}


def _staff_ids() -> list[int]:
    return list(User.objects.filter(role__in=[Role.OWNER, Role.ASSISTANT], is_active=True).values_list("pk", flat=True))


@transaction.atomic
def create_request(actor: User, data: dict) -> ServiceRequest:
    # The owner holds every capability, but a request always belongs to the client who files it.
    if actor.role != Role.CLIENT or not can(actor, Cap.CREATE_REQUEST):
        raise DomainError("Only clients can file requests.", "forbidden", 403)
    request = ServiceRequest.objects.create(client=actor, **data)
    record(actor, "request.created", request)
    notify(_staff_ids(), "request.created", f"New request {request.code}: {request.title}", service_request=request)
    return request


@transaction.atomic
def update_request(actor: User, request_id, changes: dict) -> ServiceRequest:
    if not can(actor, Cap.MANAGE_REQUESTS):
        raise DomainError("You may not manage requests.", "forbidden", 403)
    request = ServiceRequest.objects.select_for_update().get(pk=request_id)
    if request.status == Status.DONE:
        raise DomainError("Finished requests cannot be changed.", "request_closed", 409)
    changed_status = False
    if "status" in changes and changes["status"] != request.status:
        if STATUS_ORDER.index(changes["status"]) < STATUS_ORDER.index(request.status):
            raise DomainError("A request cannot move backwards.", "invalid_transition", 409)
        request.status, changed_status = changes["status"], True
    if "assignee" in changes:
        assignee = changes["assignee"]
        if assignee is not None and (not assignee.is_active or assignee.role == Role.CLIENT):
            raise DomainError("The executor must be an active staff member.", "invalid_assignee", 400)
        request.assignee = assignee
    for field in EDITABLE_BY_STAFF & changes.keys():
        setattr(request, field, changes[field])
    request.save()
    record(actor, "request.updated", request, fields=sorted(changes))
    if changed_status:
        notify(
            [request.client_id],
            "request.status",
            f"{request.code}: {request.get_status_display()}",
            service_request=request,
            exclude=actor,
        )
    return request


@transaction.atomic
def add_message(actor: User, request: ServiceRequest, body: str) -> RequestMessage:
    body = body.strip()
    if not body:
        raise DomainError("The message is empty.", "invalid_message", 400)
    message = RequestMessage.objects.create(request=request, author=actor, body=body)
    recipients = _staff_ids() if actor.role == Role.CLIENT else [request.client_id]
    notify(recipients, "request.message", f"New message on {request.code}", service_request=request, exclude=actor)
    return message
