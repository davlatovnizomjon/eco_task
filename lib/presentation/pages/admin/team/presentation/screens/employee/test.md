# Employee profile (boss) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getUser` — GET `users/{id}`

- [ ] Success: a worker id → 200 with the account with `activeCount`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Unknown id → 404 shown in the dialog.

### `TasksRepository.getTasks` — GET `tasks?who={id}`

- [ ] Success: the employee id → 200 with only tasks involving that employee; the parsed model matches the payload.
- [ ] Values: active + history counts add up to the total; “on time” counts `done` tasks finished no later than their deadline.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

## 2. Mobile/Web Integration Test

- [ ] Open an employee from the directory and from a task's assignee row; switch active/history; admin sees the permissions button.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The three counters, the money card (rewards, paid, approved expenses, in review) and the task list agree with the task details of the same employee.

## 4. Logical/Business Test

- [ ] A manager cannot see employees outside their team (404).
