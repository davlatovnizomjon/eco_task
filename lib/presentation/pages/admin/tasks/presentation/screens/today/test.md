# Today's tasks (admin) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getDashboard` — GET `dashboard` (field `dueToday`)

- [ ] Success: 200 → the list shows exactly the tasks of `dueToday`; the cached summary is shown first.
- [ ] Auth error: missing/expired token → 401 → the session is cleared and the router returns to sign-in.

## 2. Mobile/Web Integration Test

- [ ] Open from the dashboard's “Hammasi” link; the chips filter locally (Hammasi, Jarayonda, Yangi, Kechikkan) and show live counts; tapping a row opens the task.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Each row has the time (or “—” when overdue), a status dot, title, assignees (+ lateness note) and a status chip; the date line shows the weekday and “N / M bajarildi”.

## 4. Logical/Business Test

- [ ] Overdue tasks are counted in the “Kechikkan” chip and also in “Hammasi”; done tasks are counted in the “bajarildi” figure.
