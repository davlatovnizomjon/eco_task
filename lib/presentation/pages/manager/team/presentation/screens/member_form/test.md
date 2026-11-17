# Open an account: employee or client (manager) — Test Plan

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

- [ ] Open the employee form (name, phone, login, temporary password with a regenerate button, a single “Xodim” role radio — a manager cannot create managers) and the client form (name, phone, login, password, address); submit and read the hand-over dialog with the login and the password.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] The pinned bottom bar shows the hint “Hisob ochilgach, login va parolni ulashasiz” above the primary button; role rows show a radio mark.
- [ ] Boards 1.23 / 1.25: the staff form is “Xodim qo‘shish” with name, phone, login, password and a one-row role list (“Xodim”), saved with “Saqlash”; the client form has the “Jismoniy shaxs / Tashkilot” tabs (the first field becomes “Tashkilot nomi”), address, and ends with “Mijoz hisobini ochish”; the organization flag is sent as `isOrg`.

## 4. Logical/Business Test

- [ ] Empty name or login and an invalid phone block submitting with the first error in the dialog; a taken login is reported by the API.
- [ ] Client organization tab also has “Mas‘ul shaxs” (`contactPerson`) and every client has “Izoh” (`note`); both reach `POST users` and `PATCH users/{id}`.
- [ ] Edit mode (`/team/new?edit=<id>`): loads the account, prefills name, phone, address, organization flag, contact and note; login, password and role rows are hidden; saving pops with `true`.
