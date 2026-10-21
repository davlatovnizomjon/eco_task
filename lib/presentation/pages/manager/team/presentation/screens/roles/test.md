# Roles and permissions (admin) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getPermissions` / `savePermissions` — GET/PUT `users/{id}/permissions`

- [ ] Success: load, change role and switches, save → 200 with the stored `{role, flags}`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a saved change is returned by the next GET (persisted in the mock store).
- [ ] Parameter error: an unknown `role` falls back to `worker` → the backend `detail` text is shown verbatim in the shared dialog.

## 2. Mobile/Web Integration Test

- [ ] Open from an employee profile as admin, change role and two switches, save, reopen and see the same values.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The role segmented control, two switch groups with their hints and the scope notice render; Save shows a loading state and closes on success.

## 4. Logical/Business Test

- [ ] Only an admin can open this screen (the entry exists only on the admin's employee profile).
