# Account form (staff/client) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.addUser` — POST `users`

- [ ] Success: a staff and a client payload with a generated temporary password → 200 with the created `AppUser`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Taken login → 409 `detail` “login is taken” shown in the dialog.
- [ ] Parameter error: empty name or login, or a phone that is not `+998` with 9 digits, is rejected locally → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: the new account can sign in with `login` and the shown temporary password and lands on the matching home.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Open a staff account (worker and manager roles) and a client account; sign in as each.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Nothing is red before the first submit; failed submit shows the first message in the dialog and marks all invalid fields; the phone field masks as `+998 90 123 45 67`; regenerate gives a new password; success dialog shows login + password and closing returns to the directory.

## 4. Logical/Business Test

- [ ] Role choice is offered only for staff; the team of a new staff member is the creator's team.
