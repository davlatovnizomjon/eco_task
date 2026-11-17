# Employee rating (manager) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports` (field `people`)

- [ ] Success: for each period → 200; the screen ranks `people` by `done`, best first.
- [ ] Auth error: missing/expired token → 401 → the session is cleared and the router returns to sign-in.

## 2. Mobile/Web Integration Test

- [ ] Open from the dashboard's “Reyting” link; switch Shu hafta / Shu oy / Chorak; tap a row to open the employee profile.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] The first place is a filled green circle, places 2–3 a tinted circle, the rest plain gray numbers; each row shows the avatar, name, `done/total`, a progress bar and the on-time percentage.

## 4. Logical/Business Test

- [ ] The percentage is on-time completions divided by completed tasks (0 when nothing is completed).
