# Auth (sign-in) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `SessionRepository.login` — POST `auth/login`

- [ ] Success: `{login, password}` of each demo account (`jamshid`, `malika`, `boris`, `gulnora`, password `1234`) → 200 with `{token, user}` and the matching `role`; the parsed model matches the payload.
- [ ] Wrong credentials: unknown login or wrong password → 401 → `MessageErrorResponse(statusCode: 401)` (not `UnAuthorizedResponse`); the session is not cleared.
- [ ] Parameter error: empty `login` or `password` is rejected locally before any request → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: `user.role` decides the home tabs: owner (admin)/assistant (manager) → 5 boss tabs, worker → 5 worker tabs, client → the Telegram-bot notice (no tabs).
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Sign in as each of the four roles, land on the right home and keep the session after an app restart (secure storage).
- [ ] Sign out from the profile, then sign in as another role without stale data (caches are cleared).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Nothing is red before the first submit; a failed submit shows the FIRST invalid field in the shared error dialog while every invalid field turns red; fixing a field clears its red immediately.
- [ ] Wrong credentials show the inline red banner with the attempts left (5 → 4 → …) and red fields, with no dialog.
- [ ] The password eye toggles masking; the demo-account chips fill login and password.

## 4. Logical/Business Test

- [ ] The attempts counter never goes below 0 and resets when the screen is reopened.
- [ ] Login is case-insensitive and trimmed; the password is case-sensitive.
