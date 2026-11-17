# Group edit (admin)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `PATCH conversations/{id}` (title), `POST .../members/`, `DELETE .../members/{id}/`

- [ ] Success: the new title and the member diff are applied in that order; a worker's attempt → 403; an empty title → 400.
- [ ] Foreign id → 404; a failure midway keeps what was already applied and shows the error dialog.

## 2. Mobile/Web Integration Test

- [ ] Run with `AppConfig.useMockData = true` and against the live API; pull to refresh; retry after an error.

## 3. UI Test

- [ ] Board 3.4 edit: the group tile, “Guruh nomi” field, “A’zo qo‘shish” row (opens the picker of people not yet in the group) and member rows with a red minus (the caller's own row has none); “Saqlash” applies everything and closes. An empty title turns the field red only after the first save attempt.
- [ ] Photo change is not built (no file service).
- [ ] No overflow at 320 px and 768 px; light and dark themes; uz, uz-Cyrl and ru without missing keys.

## 4. Logical/Business Test

- [ ] The caller cannot remove themselves here (use “Guruhdan chiqish”).
- [ ] Nothing is sent when the draft equals the server state.
