# Statistics (six worker statistics screens)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getStats` — GET `reports/stats?kind=&period=&offset=`

- [ ] Success for every `kind` (`finance`, `tasks`, `mine`, `clients`, `staff`, `managers`) and `period` (`week`, `month`, `year`): 200 with `total`, `delta`, `bars`, `facts`, `people` as the kind needs; the parsed `StatsReport` matches.
- [ ] Auth error: 401 → `UnAuthorizedResponse`; the session is cleared.
- [ ] Values: the sum of `split` equals `total` (tasks); `delta` is the percent against the previous window (staff: a head count); `bars` has 7 / 4 / 12 entries for week / month / year; `plan` ≥ 0.
- [ ] Mock/live parity: the live backend has no such endpoint yet — until it has, the live app answers this call from the mock store.

### `ReportsRepository.exportStats` — POST `reports/export`

- [ ] Success: 200; the screen shows the “Hisobot yuklab olindi” dialog. Failure: the shared error dialog.

## 2. Mobile/Web Integration Test

- [ ] Open each kind from the report tab; switch Hafta / Oy / Yil (the window resets to the current one); step with the arrows (the “next” arrow is dimmed on the current window); pull to refresh; retry after an error.
- [ ] Download: the action turns into a spinner, then the success dialog; it is disabled while loading or when the window is empty.
- [ ] Run on a real or emulated device with `AppConfig.useMockData = true` and against the live API.

## 3. UI Test

- [ ] Boards 4.2–4.7 (all periods, loading, download, empty, error variants) match 1:1 in light and dark themes: head card with the 30 px number and the green / red change chip, tiles, bar chart (tallest bar solid), plan card, fact rows, person rows, the “Yangi / Hammasi” pills of the clients screen.
- [ ] Finance hides “Kutilayotgan to‘lovlar” when nothing is pending; tasks and own show “Kechikkan vazifa yo‘q” when nothing is overdue; clients show the “Yangi mijoz yo‘q” card when nobody was added in the window.
- [ ] Empty window → tile + title + hint of the kind; failed first load → “Ma’lumotni yuklab bo‘lmadi” with “Qayta urinish”.
- [ ] No overflow at 320 px and 768 px; uz, uz-Cyrl and ru without missing keys.

## 4. Logical/Business Test

- [ ] A response for a window the user already left is dropped (fast arrow taps show the last window only).
- [ ] The future does not exist: offset never goes above 0.
- [ ] The cached window is shown instantly on return, then refreshed; an error with cached data keeps it and shows the dialog.

## Worker differences (boards `Xd*` 4.4)

- [ ] The statistics is the shell's fourth tab “Statistika” (no back button, clears the floating bar) and shows only “Mening statistikam”: tasks given to the worker, done, on-time share, overdue and closed-with-reason; the income tile appears only when the backend sends an amount. The backend answers 403 for every other kind.
