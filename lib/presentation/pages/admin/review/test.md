# Review queue (boss) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?status=rev`

- [ ] Success: the boss session → 200 with results waiting for a decision; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a manager sees only their team's submissions.

### `ExpensesRepository.getExpenses` — GET `expenses?filter=pending`

- [ ] Success: the boss session → 200 with pending expenses; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: each row shows the receipt flag from `hasReceipt`.

### Decisions — POST `tasks/{id}/approve`, `tasks/{id}/return`

- [ ] Success: approve and return (with and without extend) → 200 with the updated task; both lists reload and the row disappears; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

## 2. Mobile/Web Integration Test

- [ ] Approve one result and return another with each reason; counters on the dashboard and the assignee's inbox reflect both.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Tabs show the two counts; each result card shows submitter, time, id, title, result text, photo strip, late chip and the two buttons; empty queue shows the empty view; pull-to-refresh works.

## 4. Logical/Business Test

- [ ] A result submitted after the deadline shows the “N days late” chip computed from `submittedAt − due`.
