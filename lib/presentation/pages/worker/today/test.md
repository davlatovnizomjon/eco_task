# Today (worker home) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?group=active`

- [ ] Success: the worker's session → 200 with only tasks that involve the worker and are open or in review; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: the hero card is the soonest task with a quota, else the soonest open task; “today” holds open tasks due today or earlier, “tomorrow” those due tomorrow.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Open the tab, update progress from the hero card, open a card, pull to refresh.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Loading shows the shimmer placeholder cards (no spinner); an empty result shows the empty view; a failed first load shows the retry view and the retry button reloads.
- [ ] Pull-to-refresh works on a full list, a short list and the empty/error view (always-scrollable); the indicator completes when the network call finishes, not on the cached emit.
- [ ] The last row clears the system gesture bar (bottom inset is part of the scroll padding).

## 4. Logical/Business Test

- [ ] A worker with nothing open sees the friendly empty view, not a blank screen.
