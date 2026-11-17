# My task (admin's own task)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Success: 200 with `address`, `remindAt`, `createdAt`, `docName`, `files` and `comments`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Unknown id → 404 → `MessageErrorResponse` with the backend's wording.

### `TasksRepository.approve` — POST `tasks/{id}/approve`

- [ ] Success: the task comes back with status `done`; every cached list is invalidated.

### `TasksRepository.failTask` — POST `tasks/{id}/fail`

- [ ] Success with `{reason}`: the task comes back with status `fail` and the reason kept as its result.
- [ ] Parameter error: an empty reason is rejected by the live API (400 → `ValidationErrorResponse`); the app never sends one.

### `TasksRepository.deleteTask` — DELETE `tasks/{id}`

- [ ] Success on the mock: the task disappears from every list.
- [ ] Live API: there is no delete endpoint yet → `MessageErrorResponse` (501) is shown and the task stays.

## 2. Mobile/Web Integration Test

- [ ] From the dashboard tap a card of the “my tasks” stack → this screen opens with the same task; pull to refresh reloads it.
- [ ] “⋯” → “Tahrirlash” opens the task form and the screen reloads on return; “O‘chirish” opens the confirmation, the confirm button spins and the screen pops to the dashboard.
- [ ] “Bajarilmadi” opens the reason sheet; sending a reason closes the task and pops; “Bajarildi” closes the task and pops.
- [ ] The address row opens the maps sheet (Yandex / Google links leave the app); the photos row opens the viewer; the note card opens the notes screen and the latest note is fresh on return.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] The design matches boards 1.8–1.9e and 1.11–1.12 of `Eco Tasks — mobile app` 1:1 in light and dark themes.
- [ ] Description: clamped to five lines with “Ko‘proq”; tapping unfolds it and the link becomes “Kamroq”; a short description shows no link (1.8a, 1.8b).
- [ ] Details card hides the rows it has no data for: no photos (1.8c–1.8e), no document, no reminder, no address.
- [ ] The deadline row shows “· N soat” in amber only for an open task due within 24 hours.
- [ ] The bottom bar is hidden for a closed task; both buttons are 52 px high and share the width.
- [ ] Reason sheet: nothing is red before the first submit; an empty submit turns the field red with “Sababini yozing”; the counter follows the text up to 500.
- [ ] No overflow at 320 px and 768 px widths; uz, uz-Cyrl and ru render without missing keys.

## 4. Logical/Business Test

- [ ] A task closed as done or failed no longer appears in the dashboard “my tasks” stack.
- [ ] Deleting needs the confirmation first; dismissing the dialog changes nothing.
- [ ] The reason typed in the sheet is the one stored on the failed task.
