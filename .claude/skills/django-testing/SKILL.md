---
name: django-testing
description: >-
  How tests are written in the Eco Tasks backend (pytest + pytest-django + DRF APIClient). Use when adding or
  updating backend tests, or when a backend change needs coverage. Covers fixtures, the policy matrix, IDOR,
  error-envelope and audit assertions, and how to run them (only when the user asks).
---

# Backend testing

Config: `pyproject.toml` -> `DJANGO_SETTINGS_MODULE = config.settings.test`, `python_files = test_*.py`,
`asyncio_mode = auto`. Tests live in `backend/tests/test_<area>.py`; shared fixtures in `tests/conftest.py`.
Run from `backend/` (only when the user asks): `.venv/bin/pytest -q` and `.venv/bin/ruff check .`

## Fixtures (conftest.py)

- Users per role: `owner`, `assistant`, `worker`, `worker2`, `client_user`, `client2`; custom ones via
  `make_user(username, Role.X, **extra)`.
- `api_as(user)` / `as_user` fixture -> `APIClient` with a real bearer token (`AuthToken.issue`). Use it instead of
  `force_authenticate` so the auth path is exercised.
- Cache is cleared around every test (throttles depend on it). `PASSWORD` is the shared strong test passphrase.
- Mark modules with `pytestmark = pytest.mark.django_db`.

## What every endpoint test file covers

1. **Happy path** for each permitted role (status code + body shape, `/api/v1/...` URL).
2. **Capability matrix** — a forbidden role gets `403` with `error.code == "forbidden"`.
3. **IDOR** — another worker/client requesting a foreign id gets `404`, same as a non-existent id.
4. **Validation** — bad/missing/over-long input -> `400` with the `{"error": {...}}` envelope; unknown or
   read-only fields are ignored (no mass assignment).
5. **Business rules** — closed objects, invalid transitions (`409 invalid_transition`), stale `version`
   (`409 version_conflict`), reason-required moves.
6. **Side effects** — `AuditLog.objects.filter(action="...")`, history rows, notifications created for the right
   audience and not for the actor.
7. **Secrets** — responses never contain password/hash/token digests; audit metadata never contains passwords.

## Style

- One behavior per test, descriptive snake_case names, assert on `r.status_code` and `r.data["error"]["code"]`.
- Create data through services or factories in the test, not fixtures files; keep tests independent.
- Pure rule tables (`transitions.RULES`, `can()`) are tested without the DB or HTTP.
- WebSocket consumers: `channels.testing.WebsocketCommunicator` (daphne stub is already in `conftest.py`).
- Throttle tests loop requests until a `429` appears (see `test_login_is_throttled`).
- Comments in English; no sleeping, no network.
