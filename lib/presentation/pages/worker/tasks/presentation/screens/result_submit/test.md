# Result submission (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.submitResult` — POST `tasks/{id}/submit`

- [ ] Success: `{text}` after attaching at least one photo → 200 with the task in status `rev` with `submittedAt`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: no photo attached is rejected locally with the photo message → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: the boss gets a `review` inbox entry and the task appears in the review queue.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Success: `ECO-142` → 200 with the task used for the checklist; the parsed model matches the payload.

## 2. Mobile/Web Integration Test

- [ ] Submit a result: both this screen and the details screen close, the task shows “in review” and the worker's list updates.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The three-point checklist reflects real data (quota reached, expenses entered, photos attached) and updates as photos are added; the photo error appears only after the first send.

## 4. Logical/Business Test

- [ ] The checklist is informational: a task with an unmet quota can still be submitted (the boss decides).
- [ ] A submitted task cannot be submitted again until it is returned.
