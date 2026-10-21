# Team progress (manager) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=week|month`

- [ ] Success: the manager session → 200 with `people` stats of the team's workers; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: `done <= total`, `onTime <= done`, and `lateDays > 0` only for workers with an overdue open task.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

## 2. Mobile/Web Integration Test

- [ ] Open from the manager dashboard's report link; switch week/month.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] One card per worker: avatar, name, “on time x / y” or the amber late line, and the done/total counter; the team-only notice is visible.

## 4. Logical/Business Test

- [ ] Only the manager's own team members are listed.
