# Task form (create/edit) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff`

- [ ] Success: the staff directory → 200 with assignable people; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a manager gets only their team; an admin gets all staff.

### `TasksRepository.createTask` / `editTask` — POST `tasks` / PUT `tasks/{id}`

- [ ] Success: a valid draft (title, due, assignees with optional quotas, priority, reward) → 200 with the created/updated task and a new inbox entry for every assignee except the creator; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: an empty title or no assignees is rejected locally before any request → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: editing keeps each assignee's reported `done` progress; the reward is sent as an integer without separators.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Create a task for one and for several assignees (with and without per-person quotas), then edit it from the details screen; the list and details show the change.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Nothing is red before the first Save; Save with an empty form shows the title message in the dialog and marks title and assignees red; fixing a field clears its error.
- [ ] The assignee sheet is searchable and shows the boss as “myself”; the deadline sheet has quick days, a month calendar and hour chips and returns one moment; the reward field groups thousands while typing and shows its unit `($)`.

## 4. Logical/Business Test

- [ ] A deadline in the past can be saved but the task is shown overdue immediately; a quota of 0 or empty means a yes/no task without a progress bar.
- [ ] Leaving the form with the system back button discards the draft without saving.
