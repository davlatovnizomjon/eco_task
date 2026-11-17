# Login and password (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `SessionRepository.changePassword` — POST `account/password` (live: `POST auth/password/`)

- [ ] Success: `{oldPassword, newPassword}` → 200 with `{token}`; the fresh token replaces the stored one and later requests use it.
- [ ] Parameter error: a wrong current password → 400 with the backend `detail` shown in the shared dialog; nothing changes.
- [ ] Auth error: expired token → 401 → the session is cleared and the router returns to sign-in.
- [ ] Login change: `PATCH account {login}` renames the account on the live API; the mock refuses it with a clear message.

## 2. Mobile/Web Integration Test

- [ ] Open from the profile edit screen; change only the password, only the login, both, or neither (saving then just closes).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Password fields are masked; the hints “Faqat lotin harflari, raqam va nuqta” and “Kamida 8 ta belgi” sit under their fields.

## 4. Logical/Business Test

- [ ] A new password needs the current password, at least 8 characters and an identical repeat; the first failing rule is shown in the dialog and nothing is sent.
