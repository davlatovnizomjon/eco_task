# Employee tasks (admin)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?who={id}`

- [ ] Success: page 1 of the member's tasks; every item involves that member.
- [ ] Auth error: 401 → `UnAuthorizedResponse`.
- [ ] Cached-first: reopening shows the cached rows at once, then the fresh ones; an error with cached rows keeps them and shows the dialog.

## 2. Mobile/Web Integration Test

- [ ] Open from “Batafsil” of the profile; switch the three tabs; tap a row → task details; pull to refresh; retry after an error.
- [ ] Run with `AppConfig.useMockData = true` and against the live API.

## 3. UI Test

- [ ] Boards 1.22c–1.22g: the title is “{name} vazifalari”; tabs Barchasi / Bajarilgan / Bajarilmagan; rows with the status marker, title, status word and the deadline day; shimmer while loading; the three empty states (tile, title, hint).
- [ ] No overflow at 320 px and 768 px; light and dark themes; uz, uz-Cyrl and ru without missing keys.

## 4. Logical/Business Test

- [ ] “Bajarilgan” lists only done tasks and “Bajarilmagan” only failed ones; “Barchasi” lists everything including open ones.
