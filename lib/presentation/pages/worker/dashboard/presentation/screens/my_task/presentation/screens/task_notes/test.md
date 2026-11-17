# Task notes (personal notes of an own task)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Success: 200; `comments` are returned oldest first and parsed into `CommentModel`.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`.

### `TasksRepository.addComment` — POST `tasks/{id}/comments`

- [ ] Success with `{text}`: the answer contains the new note last; cached lists are invalidated.
- [ ] Parameter error: an empty `text` → 400 → `ValidationErrorResponse`; the app never sends one.

### `TasksRepository.deleteComment` — DELETE `tasks/{id}/comments/{index}`

- [ ] Success on the mock: the note at `index` is gone and the others keep their order.
- [ ] Live API: no such endpoint yet → `MessageErrorResponse` (501); the list is reloaded and the note is back.

## 2. Mobile/Web Integration Test

- [ ] Open the notes from the note card of the own-task screen; type a note and send it → it appears last, tagged “Oxirgi”, and the input clears.
- [ ] Swipe a note left → the red “O‘chirish” panel shows; completing the swipe removes it.
- [ ] Pull to refresh reloads the list; run with `AppConfig.useMockData = true` and against the live API.

## 3. UI Test

- [ ] The design matches boards 1.10 and 1.10a of `Eco Tasks — mobile app` 1:1 in light and dark themes.
- [ ] Empty list shows “Hali eslatma yo‘q” and stays pullable; the input bar rises above the keyboard.
- [ ] Long notes clamp with an ellipsis; no overflow at 320 px; uz, uz-Cyrl and ru render without missing keys.

## 4. Logical/Business Test

- [ ] “Oxirgi” marks only the newest note and is hidden when there is a single note.
- [ ] A whitespace-only note is not sent.
