---
name: django-project-rules
description: >-
  Architecture and conventions of the Eco Tasks Django backend (`backend/`). Use whenever you add or change
  anything in the backend: a model, migration, service, view, serializer, URL, permission, setting, management
  command or WebSocket consumer. Covers the layering (view -> serializer -> service -> model), the single
  role/capability policy, the error envelope, transactions, audit, settings, security and code style.
---

# Django backend — project rules

Stack: Django 5.2, DRF, drf-spectacular, Channels (+Redis), PostgreSQL, uvicorn, argon2. Python 3.13, ruff
(`line-length = 120`, rules `E F W I B UP S DJ`). API root: `/api/v1/` (`apps/core/api_urls.py`).
Always work inside `backend/` with `.venv`. Do not run tests/ruff/migrations unless the user asks.

## Layout

```
backend/
  config/            settings/{base,dev,prod,test}.py, env.py (typed env reader), urls.py, asgi.py
  apps/
    core/            errors.py, pagination.py, permissions.py, policies.py, api_urls.py   (shared, no models)
    accounts/        User, AuthToken, login/throttle, user lifecycle
    audit/           AuditLog + record()
    projects/ tasks/ notifications/ chat/ finance/ reports/
  tests/             conftest.py + test_<area>.py (pytest-django)
```

Per app: `models.py`, `serializers.py`, `services.py`, `views.py`, `urls.py`, optional `access.py`
(visibility querysets), `transitions.py` (pure rules), `migrations/`.

## Layering (never skip a layer)

1. **View** (`APIView`, thin): authenticate -> load object through a *visible* queryset -> validate with a serializer
   -> call ONE service function -> serialize the result. No business rules, no `if user.role == ...`.
2. **Serializer**: input shape/validation only. Writable fields are listed explicitly (no mass assignment, no
   `fields = "__all__"`). Output serializers are separate from input ones and mark everything read-only.
3. **Service** (`services.py`): all business rules. Each mutation is `@transaction.atomic`, takes `actor` first,
   re-checks authorization with `can(actor, Cap.X)`, raises `DomainError`, and writes an audit row via `record()`
   (and history / `notify()` rows where the domain needs them).
4. **Access module** (`access.py`): *one* function per resource returning the queryset a user may see
   (`visible_tasks(user)`). REST, WebSocket, files and reports all use it.
5. **Pure rule tables** (`transitions.py`): no DB access, so they are unit-testable.

`ATOMIC_REQUESTS = False` — transactions are explicit in services. Use `select_for_update()` before changing a row
that concurrent requests can touch (status changes, assignment).

## Authorization

- `apps/core/policies.py` is the only source of truth: `Role` (OWNER, ASSISTANT, WORKER, CLIENT), `Cap`,
  `ROLE_CAPS`, `can(user, cap)`, `is_staff_role(user)`. Never compare roles ad hoc in a view.
- Adding a capability = add to `Cap`, grant it in `ROLE_CAPS`, add a case to the policy-matrix test.
- Route-level gate: `permission_classes = [has_cap(Cap.X)]` (`apps/core/permissions.py`). Object-level scope comes from
  the `access.py` queryset.
- Unknown **and** forbidden ids both return 404 (`get_object_or_404(visible_qs, pk=pk)`) so ids can't be probed (IDOR).
- Assistants get no finance/audit capability by design; clients are scoped to their own records inside the service.

## Errors

One envelope: `{"error": {"code": "...", "message": ...}}` (`message` follows `Accept-Language`) (`apps/core/errors.py`).
Raise `DomainError(detail, code, status)` for business-rule violations (`forbidden` 403, `not_found` 404,
`version_conflict` 409, `invalid_transition` 409, ...). Codes are stable `snake_case` strings the Flutter app
can switch on — don't rename an existing one. Never return raw exception text or log request bodies/passwords.

## Models and migrations

- UUID primary key for externally visible aggregates (`Task`), `BigAutoField` default otherwise.
- Money is `DecimalField(max_digits=14, decimal_places=2)`, single currency (`settings.CURRENCY`).
- Encode invariants as DB `CheckConstraint`s and add `db_index`/`Meta.indexes` for every filtered column.
- Concurrent-edit models carry `version` (optimistic token); services compare it and bump it on save.
- FKs to users use `settings.AUTH_USER_MODEL` with `on_delete=PROTECT` (history must survive), `SET_NULL` only for
  optional audit-style links.
- Every model change ships a migration; never edit an applied migration.

## Settings and secrets

- Secrets come from the environment through `config/env.py` (`env.get/csv/integer/boolean`). Never hardcode them;
  `.env.example` holds placeholders only, `.env` is never committed.
- `prod.py` refuses to start without `REDIS_URL`/TLS settings; keep new required settings failing loudly there.
- Business switches live in `base.py` under "Business policy" (e.g. `TASK_COMPLETION_REQUIRES_APPROVAL`).

## Security checklist (every endpoint)

Authenticated by default (`IsAuthenticated`); bearer token only; throttle sensitive endpoints with a scoped
throttle (`login`, `upload`); validate and bound all input lengths; uploads go to private storage and are served by
an authorized view; list endpoints paginate (`StandardPagination`, max 100) and whitelist `ordering`; generic
messages on auth failure; no secrets in logs or audit metadata.

## Style

- Match surrounding code: type hints on service signatures, short docstrings explaining *why*, English comments only.
- Module/function names: `services.create_task`, `access.visible_tasks`, `Cap.APPROVE_TASK`, `Has_<CAP>` perms.
- Keep imports ruff-sorted; no `print`; use `logging.getLogger(__name__)`.
- Cross-app calls go through the other app's `services`/`access`; import inside the function only to break a cycle.

## Keep in sync with the Flutter app

The Flutter `MockDioClient` mirrors this API's JSON. When an endpoint's request/response shape, error code or
status enum changes, say so in your answer so the app's DTOs/mock data can be updated in the same task.
