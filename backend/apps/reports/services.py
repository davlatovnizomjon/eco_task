"""Statistics behind the admin report tab. Read-only: every function takes the viewing user and a window, scopes
its queries through `visible_tasks`/capabilities and returns plain JSON-ready dicts."""

import csv
import io
from datetime import date, timedelta
from decimal import Decimal

from django.conf import settings
from django.db.models import Count, F, Q, Sum
from django.utils import timezone

from apps.accounts.models import User
from apps.audit.models import AuditLog
from apps.core.errors import DomainError
from apps.core.policies import Cap, Role, can
from apps.tasks.access import visible_tasks
from apps.tasks.models import Status, Task

KINDS = ("finance", "tasks", "mine", "clients", "staff", "managers")
PERIODS = ("week", "month", "year")
MONEY_KINDS = {"finance", "managers"}  # need Cap.VIEW_FINANCE on top of Cap.VIEW_REPORTS
WORKER_KINDS = {"tasks", "mine"}  # a worker sees these two, computed over their own assigned tasks only
DONE, ACTIVE, NEW, CLOSED_BAD = Status.COMPLETED, (Status.IN_PROGRESS, Status.REVIEW), Status.OPEN, (
    Status.CANCELED,
    Status.FAILED,
)  # fmt: skip


def window(period: str, offset: int, today: date | None = None) -> tuple[date, date]:
    """First and last day (inclusive) of the window `offset` periods from the current one (0 or negative)."""
    today = today or timezone.localdate()
    if period == "week":
        start = today - timedelta(days=today.weekday()) + timedelta(weeks=offset)
        return start, start + timedelta(days=6)
    if period == "month":
        index = today.year * 12 + today.month - 1 + offset
        year, month = divmod(index, 12)
        start = date(year, month + 1, 1)
        end = date(year + (month + 1) // 12, (month + 1) % 12 + 1, 1) - timedelta(days=1)
        return start, end
    start = date(today.year + offset, 1, 1)
    return start, date(start.year, 12, 31)


def buckets(period: str, start: date, end: date) -> list[tuple[date, date]]:
    """Bar slots of a window: 7 days, 4 week-parts of a month, 12 months of a year."""
    if period == "week":
        return [(start + timedelta(days=i),) * 2 for i in range(7)]
    if period == "year":
        return [window("month", 0, date(start.year, m, 1)) for m in range(1, 13)]
    size = (end - start).days // 4 + 1
    return [(start + timedelta(days=i * size), min(end, start + timedelta(days=i * size + size - 1))) for i in range(4)]


def _pct_change(now: int | Decimal, before: int | Decimal) -> int | None:
    return None if not before else round((now - before) * 100 / before)


def _money(qs, currency: str) -> Decimal:
    return qs.filter(currency=currency).aggregate(s=Sum("agreed_value"))["s"] or Decimal(0)


def _on_time_pct(done_qs) -> int:
    """Share of finished tasks closed on or before their deadline (no deadline counts as on time)."""
    total = done_qs.count()
    if not total:
        return 0
    on_time = done_qs.filter(Q(due_date__isnull=True) | Q(completed_at__date__lte=F("due_date"))).count()
    return round(on_time * 100 / total)


def _avg_days(done_qs) -> float:
    spans = [
        (t.completed_at - t.created_at).total_seconds() / 86400 for t in done_qs.only("created_at", "completed_at")
    ]
    return round(sum(spans) / len(spans), 1) if spans else 0.0


def _brief(user: User) -> dict:
    return {"id": user.pk, "username": user.username, "full_name": user.full_name, "avatar_url": user.avatar_url,
            "role": user.role}  # fmt: skip


def _may_view(user: User, kind: str) -> bool:
    """Staff with `VIEW_REPORTS` (money screens also need `VIEW_FINANCE`); a worker only their own numbers."""
    if can(user, Cap.VIEW_REPORTS):
        return kind not in MONEY_KINDS or can(user, Cap.VIEW_FINANCE)
    return getattr(user, "role", None) == Role.WORKER and getattr(user, "is_active", False) and kind in WORKER_KINDS


def stats(user: User, kind: str, period: str, offset: int, currency: str | None = None) -> dict:
    """Numbers of one statistics screen. Raises 403 for money screens without finance access."""
    if kind not in KINDS or period not in PERIODS or offset > 0:
        raise DomainError("Unknown statistics request.", "invalid_stats_request", 400)
    if not _may_view(user, kind):
        raise DomainError("You may not view these statistics.", "forbidden", 403)
    currency = (currency or settings.CURRENCY).upper()
    start, end = window(period, offset)
    prev_start, prev_end = window(period, offset - 1)
    slots = buckets(period, start, end)
    return {
        "finance": _finance, "tasks": _tasks, "mine": _mine, "clients": _clients, "staff": _staff,
        "managers": _managers,
    }[kind](user, start, end, prev_start, prev_end, slots, currency)  # fmt: skip


def _created(qs, a, b):
    return qs.filter(created_at__date__range=(a, b))


def _done(qs, a, b):
    return qs.filter(status=DONE, completed_at__date__range=(a, b))


def _tasks(user, start, end, ps, pe, slots, currency):
    scope = visible_tasks(user)
    window_qs, before_qs = _created(scope, start, end), _created(scope, ps, pe)
    total = window_qs.count()
    done = _done(scope, start, end)
    today = timezone.localdate()
    overdue = window_qs.filter(status__in=(NEW, *ACTIVE), due_date__lt=today).count()
    return {
        "total": total,
        "delta": _pct_change(total, before_qs.count()),
        "split": [
            window_qs.filter(status=DONE).count(),
            window_qs.filter(status__in=ACTIVE).count(),
            window_qs.filter(status=NEW).count(),
            window_qs.filter(status__in=CLOSED_BAD).count(),
        ],
        "bars": [_done(scope, a, b).count() for a, b in slots],
        "facts": [_on_time_pct(done), overdue, _avg_days(done)],
    }


def _finance(user, start, end, ps, pe, slots, currency):
    scope = visible_tasks(user)
    paid = _done(scope, start, end)
    income = _money(paid, currency)
    paid_n = paid.filter(currency=currency).count()
    planned = scope.filter(due_date__range=(start, end)).exclude(status__in=CLOSED_BAD)
    pending = planned.filter(status__in=(NEW, *ACTIVE))
    canceled = scope.filter(status__in=CLOSED_BAD, updated_at__date__range=(start, end))
    return {
        "total": income,
        "delta": _pct_change(income, _money(_done(scope, ps, pe), currency)),
        "a": paid_n,
        "b": round(income / paid_n) if paid_n else 0,
        "bars": [_money(_done(scope, a, b), currency) for a, b in slots],
        "plan": _money(planned, currency),
        "facts": [
            paid_n,
            income,
            pending.filter(currency=currency).count(),
            _money(pending, currency),
            canceled.filter(currency=currency).count(),
            _money(canceled, currency),
        ],  # fmt: skip
        "currency": currency,
    }


def _mine_as_worker(user, start, end, ps, pe, slots):
    """A worker's own screen: tasks given to them, how many they finished, on-time share, overdue and closed ones.
    There is no payout data in the system, so the income figure is 0."""
    mine = visible_tasks(user)
    given = _created(mine, start, end)
    done = _done(mine, start, end)
    return {
        "total": given.count(),
        "delta": _pct_change(given.count(), _created(mine, ps, pe).count()),
        "a": done.count(),
        "b": 0,
        "bars": [_done(mine, a, b).count() for a, b in slots],
        "facts": [
            _on_time_pct(done),
            given.filter(status__in=(NEW, *ACTIVE), due_date__lt=timezone.localdate()).count(),
            given.filter(status__in=CLOSED_BAD).count(),
        ],
    }


def _mine(user, start, end, ps, pe, slots, currency):
    if user.role == Role.WORKER:
        return _mine_as_worker(user, start, end, ps, pe, slots)
    mine = Task.objects.filter(creator=user)
    created = _created(mine, start, end)
    done = _done(mine, start, end)
    clients = AuditLog.objects.filter(
        actor=user, action="user.created", metadata__role=Role.CLIENT.value, created_at__date__range=(start, end)
    ).count()
    return {
        "total": created.count(),
        "delta": _pct_change(created.count(), _created(mine, ps, pe).count()),
        "a": done.count(),
        "b": _money(done, currency) if can(user, Cap.VIEW_FINANCE) else 0,
        "bars": [_created(mine, a, b).count() for a, b in slots],
        "facts": [
            _on_time_pct(done),
            created.filter(status__in=(NEW, *ACTIVE), due_date__lt=timezone.localdate()).count(),
            clients,
        ],
    }


def _clients(user, start, end, ps, pe, slots, currency):
    clients = User.objects.filter(role=Role.CLIENT, is_active=True)
    new = clients.filter(created_at__date__range=(start, end)).order_by("-created_at")
    counts = dict(
        visible_tasks(user)
        .exclude(client=None)
        .values_list("client")
        .annotate(n=Count("pk"))
        .values_list("client", "n")
    )

    def row(u, tasks=None):
        return {"user": _brief(u), "is_org": u.is_org, "date": u.created_at.date().isoformat(), "a": tasks or 0, "b": 0}

    return {
        "total": new.count(),
        "delta": _pct_change(new.count(), clients.filter(created_at__date__range=(ps, pe)).count()),
        "a": clients.count(),
        "b": clients.filter(is_org=True).count(),
        "people": [row(u) for u in new[:50]],
        "everyone": [row(u, counts.get(u.pk, 0)) for u in clients.order_by("full_name", "id")[:200]],
    }


def _staff(user, start, end, ps, pe, slots, currency):
    workers = User.objects.filter(role=Role.WORKER, is_active=True)
    done = Task.objects.filter(status=DONE, completed_at__date__range=(start, end))
    ranked = []
    for worker in workers:
        mine = done.filter(assignments__worker=worker).distinct()
        if mine.exists():
            ranked.append((mine.count(), _on_time_pct(mine), worker))
    ranked.sort(key=lambda r: (-r[0], r[2].pk))
    return {
        "total": workers.count(),
        "delta": workers.filter(created_at__date__range=(start, end)).count(),
        "a": done.count(),
        "b": _on_time_pct(done),
        "people": [{"user": _brief(w), "is_org": False, "date": None, "a": pct, "b": n} for n, pct, w in ranked[:10]],
    }


def _managers(user, start, end, ps, pe, slots, currency):
    managers = User.objects.filter(role=Role.ASSISTANT, is_active=True)
    rows = []
    for manager in managers.order_by("full_name", "id"):
        made = _created(Task.objects.filter(creator=manager), start, end)
        income = _money(_done(Task.objects.filter(creator=manager), start, end), currency)
        rows.append({"user": _brief(manager), "is_org": False, "date": None, "a": made.count(), "b": income})
    rows.sort(key=lambda r: -r["b"])
    return {
        "total": managers.count(),
        "previous": managers.filter(created_at__date__lt=start).count(),
        "a": sum(r["a"] for r in rows),
        "b": sum(r["b"] for r in rows),
        "people": rows,
    }


def dashboard(user: User) -> dict:
    """Numbers of the home screen: waiting approvals, today's deadlines and this week's leader board. A worker gets
    only their own deadlines (no team)."""
    is_worker = getattr(user, "role", None) == Role.WORKER and getattr(user, "is_active", False)
    if not can(user, Cap.VIEW_REPORTS) and not is_worker:
        raise DomainError("You may not view reports.", "forbidden", 403)
    scope = visible_tasks(user)
    today = timezone.localdate()
    waiting = scope.filter(status=Status.OPEN)
    start, end = window("week", 0)
    team = []
    for worker in [] if is_worker else User.objects.filter(role=Role.WORKER, is_active=True):
        mine = scope.filter(
            assignments__worker=worker, assignments__unassigned_at__isnull=True, due_date__range=(start, end)
        ).distinct()
        team.append({"user": _brief(worker), "done": mine.filter(status=DONE).count(), "total": mine.count()})
    team.sort(key=lambda r: (-r["done"], r["user"]["id"]))
    due = scope.filter(status__in=(NEW, *ACTIVE), due_date__lte=today).order_by("due_date", "id")
    return {
        "in_review": scope.filter(status=Status.REVIEW).count(),
        "overdue": scope.filter(status__in=(NEW, *ACTIVE), due_date__lt=today).count(),
        "pending_new": waiting.exclude(creator__role=Role.CLIENT).count(),
        "pending_client": waiting.filter(creator__role=Role.CLIENT).count(),
        "due_today": list(due.values_list("pk", flat=True)[:3]),
        "team": team[:4],
    }


def export_csv(user: User, kind: str, period: str, offset: int, currency: str | None = None) -> str:
    """The same numbers as `stats`, flattened to `key,value` rows for a spreadsheet."""
    data = stats(user, kind, period, offset, currency)
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["metric", "value"])
    for key, value in data.items():
        if key in ("people", "everyone"):
            for row in value:
                writer.writerow([f"{key}:{row['user']['full_name'] or row['user']['username']}", row["a"], row["b"]])
        else:
            writer.writerow([key, value])
    return out.getvalue()
