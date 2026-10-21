# Client (left menu + Telegram-bot notice) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `SessionRepository.login` — POST `auth/login/` as a client

- [ ] Success: a CLIENT account signs in (200 with token and `role: CLIENT`); the session is stored and the router moves the app to `/telegram`.
- [ ] Auth error: wrong password → 401, the sign-in form shows the backend message (no redirect).
- [ ] Mock/live parity: `gulnora` on the mock backend and a CLIENT account on the live API behave the same.

## 2. Mobile/Web Integration Test

- [ ] Sign in as a client: the bot notice opens; every attempt to open `/home`, `/tasks/...`, `/chat/...` (deep link or Back) lands on `/telegram` again.
- [ ] Restart the app with a stored client session: it opens on the notice, not on the home.
- [ ] Sign out returns to the sign-in screen; signing in as staff afterwards shows the normal home.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px).
- [ ] The left menu opens from the menu button and lists the Telegram-bot notice, Language and Appearance; the header shows the account; Language and Appearance open their settings screens.
- [ ] Light and dark themes both read correctly; Uzbek Latin, Uzbek Cyrillic and Russian render without missing keys.
- [ ] The text names the bot given by `--dart-define=TELEGRAM_BOT=@name`; “Copy” puts exactly that handle on the clipboard and shows the “copied” snackbar.

## 4. Logical/Business Test

- [ ] A client can never reach staff data through the app: no tab, no deep link and no pushed route is reachable while the role is client.
