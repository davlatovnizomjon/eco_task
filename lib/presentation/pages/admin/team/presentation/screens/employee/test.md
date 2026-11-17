# Employee profile (admin)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getUser` — GET `users/{id}` and `TasksRepository.getTasks` — GET `tasks?who={id}`

- [ ] Success: the account and the member's tasks load; the counters equal the number of returned tasks by status.
- [ ] Auth error: 401 → `UnAuthorizedResponse`. Unknown id → 404 → the shared error dialog.
- [ ] Cached-first: reopening shows the cached profile at once, then the fresh one.

## 2. Mobile/Web Integration Test

- [ ] Open from the team list and from the rating; “Batafsil” opens the full task list; a today's task opens its details; pull to refresh.
- [ ] Run with `AppConfig.useMockData = true` and against the live API.

## 3. UI Test

- [ ] Boards 1.22–1.22b: 96 px avatar, name, phone and role pill centred; the “Vazifalar” card with Barchasi / Bajarilgan / Bajarilmagan counters; “Bugungi vazifalar” rows or the “Bugun vazifa yo‘q” card.
- [ ] The “⋯” menu opens “Tahrirlash” (member form prefilled, saved with `PATCH users/{id}`) and “O‘chirish” (confirm dialog, then `DELETE users/{id}`); the toast says deleted, or deactivated when the account has history, and the screen closes.
- [ ] No overflow at 320 px and 768 px; light and dark themes; uz, uz-Cyrl and ru without missing keys.

## 4. Logical/Business Test

- [ ] Counters count done and failed tasks of this member only; “today” means the deadline day is today.
