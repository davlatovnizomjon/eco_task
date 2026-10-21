# Task status counts (boss) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=…`

- [ ] Success: each period → 200 with per-status counts and `overdue`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: the big total equals the sum of the six status rows; the overdue row is independent of status.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

## 2. Mobile/Web Integration Test

- [ ] Open from the dashboard's overdue card, switch periods, tap a row (goes to the tasks tab).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Six status chips with counts and the amber overdue row render; the team name appears in the total card.

## 4. Logical/Business Test

- [ ] A manager sees counts of their team only.
