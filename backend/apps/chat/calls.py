"""Call state machine: start, answer, decline, end, invite. Everything about who may take part is decided here;
the signalling relay in the consumer only forwards between participants of a live call."""

import logging
from datetime import timedelta

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.accounts.models import User
from apps.accounts.serializers import UserBriefSerializer
from apps.audit.services import record
from apps.core.errors import DomainError
from apps.notifications.services import notify

from .models import Call, CallParticipant, Conversation, Kind, Membership
from .services import can_access, get_conversation_for, user_group

logger = logging.getLogger(__name__)
S, P = Call.CallStatus, CallParticipant.State
LIVE = (S.RINGING, S.ACTIVE)


def call_payload(call: Call) -> dict:
    rows = call.participants.select_related("user")
    return {
        "id": call.pk,
        "conversation": str(call.conversation_id),
        "kind": call.kind,
        "status": call.status,
        "caller": UserBriefSerializer(call.caller).data if call.caller else None,
        "created_at": call.created_at.isoformat(),
        "answered_at": call.answered_at.isoformat() if call.answered_at else None,
        "ended_at": call.ended_at.isoformat() if call.ended_at else None,
        "participants": [{"user": UserBriefSerializer(p.user).data, "state": p.state} for p in rows],
    }


def _push(user_ids, event_type: str, call: Call) -> None:
    """Tell every listed person's socket about the call; best effort (a miss is recovered by the next REST read)."""
    payload = {"type": "call.event", "event": event_type, "call": call_payload(call)}
    layer = get_channel_layer()
    for uid in set(user_ids):
        try:
            async_to_sync(layer.group_send)(user_group(uid), payload)
        except Exception:
            logger.exception("call push to %s failed", uid)


def _members(conversation: Conversation) -> list[User]:
    ids = Membership.objects.filter(conversation=conversation, left_at__isnull=True).values_list("user_id", flat=True)
    return list(User.objects.filter(pk__in=ids, is_active=True))


def _finish(call: Call, status: str) -> None:
    call.status, call.ended_at = status, timezone.now()
    call.save(update_fields=["status", "ended_at"])


def expire_if_stale(call: Call) -> Call:
    """A call nobody answered in time becomes MISSED; invitees get an inbox note."""
    limit = timedelta(seconds=settings.CALL_RING_SECONDS)
    if call.status == S.RINGING and timezone.now() - call.created_at > limit:
        with transaction.atomic():
            call = Call.objects.select_for_update().get(pk=call.pk)
            if call.status == S.RINGING:
                _finish(call, S.MISSED)
                invited = list(call.participants.filter(state=P.INVITED).values_list("user_id", flat=True))
                call.participants.filter(state=P.INVITED).update(state=P.MISSED)
                notify(invited, "call.missed", "Missed call", conversation=call.conversation)
                transaction.on_commit(lambda: _push([*invited, call.caller_id], "ended", call))
    return call


def get_call_for(user: User, call_id) -> Call:
    """Only people invited to (or starting) a call may see it; everyone else gets the same 404."""
    call = Call.objects.filter(pk=call_id, participants__user=user).select_related("caller", "conversation").first()
    if call is None:
        raise DomainError("Call not found.", "not_found", 404)
    return expire_if_stale(call)


@transaction.atomic
def start_call(actor: User, conversation_id, kind: str) -> Call:
    conversation = get_conversation_for(actor, conversation_id)
    if conversation.kind == Kind.TASK:
        raise DomainError("Calls are available in direct and group chats.", "invalid_operation", 400)
    for stale in Call.objects.filter(conversation=conversation, status=S.RINGING):
        expire_if_stale(stale)
    invitees = [u for u in _members(conversation) if u.pk != actor.pk]
    if not invitees:
        raise DomainError("There is nobody to call.", "invalid_operation", 400)
    try:
        with transaction.atomic():
            call = Call.objects.create(conversation=conversation, caller=actor, kind=kind)
    except IntegrityError:
        raise DomainError("A call is already in progress here.", "call_in_progress", 409) from None
    CallParticipant.objects.create(call=call, user=actor, state=P.JOINED)
    CallParticipant.objects.bulk_create([CallParticipant(call=call, user=u) for u in invitees])
    record(actor, "call.started", call, kind=kind)
    transaction.on_commit(lambda: _push([u.pk for u in invitees], "incoming", call))
    return call


def _participant(call: Call, user: User) -> CallParticipant:
    row = call.participants.select_for_update().filter(user=user).first()
    if row is None:
        raise DomainError("Call not found.", "not_found", 404)
    return row


@transaction.atomic
def answer_call(actor: User, call_id) -> Call:
    call = get_call_for(actor, call_id)
    call = Call.objects.select_for_update().get(pk=call.pk)
    me = _participant(call, actor)
    if call.status not in LIVE or me.state not in (P.INVITED, P.JOINED):
        raise DomainError("This call is over.", "call_ended", 409)
    me.state = P.JOINED
    me.save(update_fields=["state"])
    if call.status == S.RINGING:
        call.status, call.answered_at = S.ACTIVE, timezone.now()
        call.save(update_fields=["status", "answered_at"])
    transaction.on_commit(lambda: _push(call.participants.values_list("user_id", flat=True), "answered", call))
    return call


@transaction.atomic
def decline_call(actor: User, call_id) -> Call:
    call = Call.objects.select_for_update().get(pk=get_call_for(actor, call_id).pk)
    me = _participant(call, actor)
    if call.status not in LIVE or me.state != P.INVITED:
        raise DomainError("This call is over.", "call_ended", 409)
    me.state = P.DECLINED
    me.save(update_fields=["state"])
    if not call.participants.filter(state__in=[P.INVITED, P.JOINED]).exclude(user_id=call.caller_id).exists():
        # Everybody invited said no (a direct call has one invitee): the call is over for the caller too.
        _finish(call, S.DECLINED)
    transaction.on_commit(lambda: _push(call.participants.values_list("user_id", flat=True), "declined", call))
    return call


@transaction.atomic
def end_call(actor: User, call_id) -> Call:
    call = Call.objects.select_for_update().get(pk=get_call_for(actor, call_id).pk)
    me = _participant(call, actor)
    if call.status in LIVE and me.state in (P.JOINED, P.INVITED):
        was_ringing = call.status == S.RINGING
        me.state = P.LEFT
        me.save(update_fields=["state"])
        joined_left = call.participants.filter(state=P.JOINED).count()
        if actor.pk == call.caller_id and was_ringing:
            invited = list(call.participants.filter(state=P.INVITED).values_list("user_id", flat=True))
            call.participants.filter(state=P.INVITED).update(state=P.MISSED)
            _finish(call, S.CANCELED)
            notify(invited, "call.missed", "Missed call", conversation=call.conversation)
        elif joined_left == 0 or (call.conversation.kind == Kind.DIRECT and call.status == S.ACTIVE):
            _finish(call, S.ENDED)
        transaction.on_commit(lambda: _push(call.participants.values_list("user_id", flat=True), "ended", call))
    return call


@transaction.atomic
def invite_to_call(actor: User, call_id, user_ids: list[int]) -> Call:
    """A participant who is in the call adds more members of the same group to it."""
    call = Call.objects.select_for_update().get(pk=get_call_for(actor, call_id).pk)
    if call.status not in LIVE or call.conversation.kind != Kind.GROUP:
        raise DomainError("People can only be added to a live group call.", "invalid_operation", 400)
    if not call.participants.filter(user=actor, state=P.JOINED).exists():
        raise DomainError("Join the call first.", "forbidden", 403)
    allowed = {u.pk: u for u in _members(call.conversation)}
    new = [allowed[i] for i in set(user_ids) if i in allowed and not call.participants.filter(user_id=i).exists()]
    for u in new:
        CallParticipant.objects.create(call=call, user=u)
    transaction.on_commit(lambda: _push([u.pk for u in new], "incoming", call))
    return call


def conversation_calls(user: User, conversation_id, limit: int = 30) -> list[Call]:
    conversation = get_conversation_for(user, conversation_id)
    if not can_access(user, conversation):
        raise DomainError("Conversation not found.", "not_found", 404)
    calls = list(Call.objects.filter(conversation=conversation).select_related("caller")[:limit])
    return [expire_if_stale(c) for c in calls]


def may_signal(user_id: int, other_id: int, call_id) -> bool:
    """Signalling is relayed only between two people of the same live call."""
    rows = CallParticipant.objects.filter(
        call_id=call_id, call__status__in=LIVE, user_id__in=[user_id, other_id], state__in=[P.INVITED, P.JOINED]
    )
    return user_id != other_id and rows.count() == 2
