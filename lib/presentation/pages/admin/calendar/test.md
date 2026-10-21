# Calendar — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getCalendar` — GET `tasks/calendar?month=YYYY-M`

- [ ] Success: the current and the next month → 200 with every visible task whose deadline falls into the month; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a worker sees only their tasks, a manager their team's, an admin all; a month without deadlines returns an empty list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Swipe months, tap days, open a task from the day list; the dots match the list below.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Dots: green = deadline, amber = important open task, red = overdue; weekday and month names are localized in all three languages; the legend and the day header (`weekday, day · N`) render.

## 4. Logical/Business Test

- [ ] Changing the month loads that month only; a response for a month that is no longer visible is dropped.
