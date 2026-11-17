# Reports (admin report tab)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=`

- [ ] Success: 200 with `counts`, `overdue`, `weekly`, `people`; used by the rating screen (this feature's bloc).
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared.
- [ ] Cached-first: reopening shows the cached report immediately, then the fresh one.

(The six statistics screens have their own plan in `presentation/screens/stats/test.md`.)

## 2. Mobile/Web Integration Test

- [ ] The tab lists six cards (Moliya, Vazifalar statistikasi, Mening statistikam, Mijozlar, Xodimlar, Menejerlar); each opens its statistics screen (`/reports/:kind`) and back returns to the tab.
- [ ] Run on a real or emulated device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] Board 4.1: large “Hisobot” title and six equal-height full-width cards with a 48 px tile, title, hint and a chevron; the last card clears the floating tab bar.
- [ ] No overflow at 320 px and 768 px; light and dark themes; uz, uz-Cyrl and ru without missing keys.

## 4. Logical/Business Test

- [ ] Every card's title and hint come from `StatsKind`; the cards open the matching kind.
