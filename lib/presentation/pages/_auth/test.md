# Auth (sign-in) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `SupportRepository.getContact` — GET `support/`

- [ ] Success: `{phone, telegram}` → parsed `SupportContact`; the Telegram name keeps its `@`.
- [ ] Not published: 404 `support_not_found` → `SupportContact.none` (empty state, not an error).
- [ ] Failure: no connection / 5xx → the typed `ScreenResponse` propagates and the sheet shows the retry panel.
- [ ] Mock/live parity: `MockDioClient` answers `support/` with `AppConfig.supportPhone` / `AppConfig.telegramBot`; `BackendDioClient` passes it straight through.

### `LegalRepository.get` — GET `legal/terms/` and `legal/privacy/`

- [ ] Success: `{title, message, updated_at}` → a `LegalDocument` (`updated_at` becomes the date line at the end of the text); `message` is split into sections at blank lines (`1. Heading` + text, the number dropped from the heading), a single-line part is text without a heading.
- [ ] Language: the request carries `Accept-Language` (always `uz`); a language with no published text answers the Uzbek one.
- [ ] Not published: 404 `legal_document_not_found` → `null` (empty state, not an error).
- [ ] Failure: no connection / 5xx → the typed `ScreenResponse` propagates and the sheet shows the retry panel.
- [ ] Cache: a fetched text is served from memory for the same language (no second request); a 404 or a failure is not remembered; after a language change the text is fetched again.
- [ ] Mock/live parity: `MockDioClient` answers both paths with the same shape (Uzbek text, six sections each); `BackendDioClient` passes `legal/…` straight through.

### `SessionRepository.login` — POST `auth/login`

- [ ] Success: `{login, password}` of each demo account (`jamshid`, `malika`, `boris`, `gulnora`, password `1234`) → 200 with `{token, user}` and the matching `role`; the parsed model matches the payload.
- [ ] Wrong credentials: unknown login or wrong password → 401 → `MessageErrorResponse(statusCode: 401)` (not `UnAuthorizedResponse`); the session is not cleared.
- [ ] Throttle: the live API's `429` locks the form for the `retry_after` seconds the backend names (5 minutes when it names none).
- [ ] Parameter error: an empty `login` or `password` is rejected locally before any request (amber toast, red fields).
- [ ] Values: `user.role` decides the home: owner (admin) → the bottom-tab admin shell, assistant (manager) / worker → their drawer shells, client → the Telegram-bot notice.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Sign in as each of the four roles, land on the right home and keep the session after an app restart (secure storage).
- [ ] Sign out from the profile, then sign in as another role without stale data (caches are cleared).
- [ ] The header holds only the brand (no help button). The dispatcher sheet is not reachable from the sign-in screen any more: it opens from the maintenance wall's “Dispetcher bilan bog‘lanish” button (`public/update_gate`); it loads the contacts from `GET support/` (spinner first, shown for at least 0.6 s even when the answer is instant), tapping the call row dials the number (`tel:`) and the Telegram row opens `https://t.me/<name>`; where the device cannot, the value is copied and the row shows “Nusxalandi” for two seconds. The sheet matches the `2.4 Dispetcher` board: close button top right, round headset, title and the working-hours sentence, rows 56 px tall with a chevron. No published contacts (404 or both values empty) → empty panel; a network/server failure → “Yuklab bo‘lmadi” with a working “Qayta urinish”; the contacts are fetched once per app run: reopening the sheet shows them at once with no spinner and no request, while an empty answer or a failure is not remembered and the next opening asks again. The language button opens the popup; choosing a language switches the app at once: every text on the sign-in screen (title, hint, field labels and hints, button, terms line) is re-read in the new language without leaving the screen, and the button shows its flag and code.
- [ ] The terms and privacy links in the footer open the tall legal sheets; the sheet rises to 96 px below the top, has no bottom button, and the close button (or a drag down) dismisses it. The title and the sections come from the backend, and the last line under the text is “Oxirgi yangilanish: <date>” (the backend's `updated_at`, in the app language and the phone's time zone) (edited in the Django admin → Legal documents), in the app language; the first opening shows a spinner, an unpublished text shows “Hujjat hali e‘lon qilinmagan”, a failed request shows “Yuklab bo‘lmadi” with a working “Qayta urinish”, and reopening shows the remembered text at once. The numbered headings and text match the `3.2` / `3.3` boards.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Nothing is red before the first submit; submitting with an empty field shows the amber “Login va parolni kiriting / Kirish uchun ikkala maydonni to‘ldiring.” toast and turns every empty field red (no text under the fields, as on board `2.1`); fixing a field clears its red at once. The red border/glyph fade in and reverse smoothly when cleared; focus fades the green border and halo in and out. The title reads “Kirish” with the line “Sizga berilgan login va parolni kiriting”.
- [ ] Wrong credentials show the red toast with the backend's own title and message (the app counts no attempts itself) and both fields red; the next edit clears the red fields.
- [ ] While signing in the button shows a spinner and “Kirilmoqda…”; toasts are shown through the shared `showTopToast` (see `public/toast/test.md`).
- [ ] The password eye toggles masking; in mock mode the demo-account chips fill login and password; the terms line stays at the bottom even with the keyboard closed and scrolls with the keyboard open.

## 4. Logical/Business Test

- [ ] The backend's lock answer (`429`, after `LOGIN_MAX_ATTEMPTS` wrong tries) locks sign-in for `retry_after` seconds (`LOGIN_LOCK_SECONDS`): no toast and no separate screen — the form stays and, as on board `2.3`, an amber banner with a lock glyph appears under the password field (“Siz vaqtincha bloklangansiz. mm:ss dan keyin qayta urinib ko‘ring.”, the time in bold and counting down live) and the “Kirish” button is disabled; the fields stay editable. When the countdown ends the banner goes, the button works again and the attempts reset to 5.
- [ ] The lock survives closing the app: lock sign-in, close the app with e.g. 3:00 left, reopen it after 1 minute → the banner shows about 2:00 and keeps counting; reopen after the time has run out → no banner and sign-in works. The stored end moment is erased once it has passed. (The lock is kept per device, not per login.)
- [ ] Login is case-insensitive and trimmed; the password is case-sensitive.
