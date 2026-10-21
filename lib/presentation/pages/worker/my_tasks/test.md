# My tasks (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?group=active|history`

- [ ] Success: both groups → 200 with active = open + in review; history = done, failed, canceled; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: history is sorted newest first; the month reward sums rewards of `done` tasks and the paid sum only those with `isPaid`.
- [ ] Paging: opening the list issues exactly ONE request for page 1 (`pageSize` = the repository constant); the next page is requested only when scrolling near the end; pull-to-refresh reloads page 1 and resets the list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Switch between active and history; open the pushed history screen from the profile (back button present, history tab first).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Loading shows the shimmer placeholder cards (no spinner); an empty result shows the empty view; a failed first load shows the retry view and the retry button reloads.
- [ ] Pull-to-refresh works on a full list, a short list and the empty/error view (always-scrollable); the indicator completes when the network call finishes, not on the cached emit.
- [ ] The last row clears the system gesture bar (bottom inset is part of the scroll padding).

## 4. Logical/Business Test

- [ ] Switching tabs quickly never shows the other tab's rows (stale responses dropped).
