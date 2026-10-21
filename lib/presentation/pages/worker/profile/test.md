# Profile (shared frame) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getProfile` — GET `profile/summary`

- [ ] Success: each role → 200 with role-specific numbers; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a worker's `monthReward`/`paidReward` equal the sums over their `done` tasks; a boss gets `pendingExpenses` and `teamSize`, a worker gets zeros there.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

## 2. Mobile/Web Integration Test

- [ ] Open settings screens from the list, sign out (confirm) and sign in as another role.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Account card; the role's own cards (worker: month card with history link; admin/manager: none, their shortcuts are in the left menu); settings rows show the current language, theme and notification state; the reminder row is hidden for clients.

## 4. Logical/Business Test

- [ ] Sign-out always asks for confirmation first and clears the session, caches and the selected tab.
