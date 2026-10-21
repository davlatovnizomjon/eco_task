# Reports (boss) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=week|month|quarter`

- [ ] Success: each period → 200 with counts per status, `overdue`, `lateDelivered`, `weekly`, money totals, `people`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: `sum(counts) == total`; a shorter period never reports more tasks than a longer one; money totals equal the sums over the same tasks.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Switch the three periods and pull to refresh; compare the numbers with the task list filters.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Status card, weekly bar chart (the last bar highlighted, bars scale to the tallest) and money card render; the chart never overflows with zero or large values.

## 4. Logical/Business Test

- [ ] Switching period quickly shows the last chosen period's numbers only.
