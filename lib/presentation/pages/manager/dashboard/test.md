# Dashboard (boss home) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getDashboard` — GET `dashboard`

- [ ] Success: the request as admin and as manager → 200 with counts, `dueToday` (≤ 3) and `team` (≤ 4); the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: `inReview` equals the number of tasks in status `rev`; `overdue` equals open tasks past their deadline; `pendingExpenses` equals the pending rows of `GET expenses?filter=pending`.
- [ ] Values: a manager sees only their team's workers and tasks; an admin sees everyone.
- [ ] Values: `dueToday` is sorted by deadline and contains only open tasks due today or earlier.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Open the dashboard, pull to refresh, tap each stat card (review, overdue, expenses), “all” link, team report link and the bell; each lands on the right screen.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Skeleton shimmer while the first load runs; the manager banner shows the team name and size; the FAB opens the new-task form.
- [ ] The bell badge follows the unread counter.

## 4. Logical/Business Test

- [ ] After approving a result or reviewing an expense elsewhere, returning to the dashboard shows updated counters (cache invalidated).
