# Task details (manager) — Test Plan

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

- [ ] Open from the list, the dashboard, the calendar and an employee profile; “⋯” → “Tahrirlash” opens the form and the task reloads on return; “⋯” → “O‘chirish” asks for confirmation, spins and pops; approve / return a result that waits for a decision; tap a photo → the viewer opens on it; “Yana N kishi” opens the full assignee sheet.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Boards 2.6: the bar shows “Vazifa tafsiloti” and the “⋯” action; then the title and description, the facts card (Holat chip, Tashkilot nomi / Mijoz, Muddat, Manzil, Narx in the task's currency, Yaratgan, Yaratilgan sana — rows without data hidden), the photo thumbnails and the first three assignees with role pills (Xodim green, Menejer blue, Manager amber).
- [ ] The bottom bar shows Rad etish / Tasdiqlash only for a task in review; open and closed tasks have no bar (edit and delete live in the “⋯” menu).

## 4. Logical/Business Test

- [ ] Approving or deleting closes the screen and the lists reflect it; returning a result keeps the screen open on the refreshed task; deleting needs the confirmation first.
- [ ] The price is written in the task's own currency (`uzs` → “so‘m”, otherwise “$”); a task without a client hides the client row, one for a private person labels it “Mijoz”.
- [ ] The "⋯" menu offers "Tahrirlash" and "O‘chirish" for any task (owner and manager may delete any task).
