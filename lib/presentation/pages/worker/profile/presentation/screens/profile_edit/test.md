# Profile edit (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `SessionRepository.updateAccount` — PATCH `account` (live: `PATCH users/{me}/`)

- [ ] Success: `{name}` → 200 with the updated account; the stored session and the `user` notifier carry the new name at once.
- [ ] Auth error: expired token → 401 → the session is cleared and the router returns to sign-in.
- [ ] Mock/live parity: the mock keeps the login fixed and renames only; the live API renames through the users endpoint.

## 2. Mobile/Web Integration Test

- [ ] Open from the profile header action; edit the first and last name and save; the profile header and the dashboard greeting show the new name.
- [ ] The “Login va parolni o‘zgartirish” row opens the login and password screen.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.

## 4. Logical/Business Test

- [ ] An empty first name blocks saving and shows the error dialog; the last name is optional.
