# Task details — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Success: `ECO-142` → 200 with the task with assignees, expenses, comments and log; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Unknown id → 404 → `MessageErrorResponse(statusCode: 404)` shown in the dialog.
- [ ] Values: `ratio = totalDone / totalShare`; `isOverdue` only for open tasks past their deadline; the log is newest first.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

### Actions — POST `tasks/{id}/comments`, `/progress`, `/approve`, `/return`, `/cancel`

- [ ] Success: each action as the right role → 200 with the updated task; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: an empty comment is rejected locally; `done` above the worker's share is clamped by the stepper → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: progress moves a `fresh` task to `prog` and adds log lines; `cant=true` → `fail`; approve → `done`; return → `prog` (+2 days when extended); cancel → `canc`.
- [ ] Values: approve/return create an inbox entry for every assignee; comments notify the other participants.

## 2. Mobile/Web Integration Test

- [ ] Boss path: open a `rev` task → approve (screen closes) and reject with each reason (sheet, extend switch) → status returns to `prog`.
- [ ] Worker path: open an assigned task → update progress (stepper, outcome, note), comment with photos, add an expense, submit the result.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Sections appear only when they have content (result, reward/expenses, files, activity); the boss sees assignee rows with per-person progress, the worker sees their own share card and only their own expenses.
- [ ] Bottom bar by role/status: approve+reject (boss, `rev`), cancel+edit (boss, open), four worker actions (worker, open), none for closed tasks; destructive cancel asks for confirmation first.
- [ ] Pull-to-refresh works; the comment field sends and clears; the timeline marks the newest log line.

## 4. Logical/Business Test

- [ ] A worker who is not assigned cannot reach the worker actions; a manager cannot open tasks outside their team (404 from the backend).
- [ ] Approving twice or acting on a canceled task is rejected by the UI (buttons hidden) and the backend.
