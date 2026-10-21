# Settings (language, appearance, notifications, reminders) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

- [ ] No network endpoints: this feature only reads/writes local state (see sections 2–4).

## 2. Mobile/Web Integration Test

- [ ] Every switch and choice persists through `LocalStore` and is restored after an app restart: theme mode, bigger text, notification switches, reminder offsets, quiet hours, digest, daily reminder.
- [ ] Language changes apply app-wide at once (no restart) and are remembered by `easy_localization`.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Appearance: system / light / dark rows show a check on the active one; choosing dark repaints the whole app immediately, including screens already open under it.
- [ ] Notification screen: the switch list differs by role (boss: review, expense, request; worker: decision only; client: no groups).
- [ ] Reminder screen: offsets can be multi-selected; the morning digest time row is informational.

## 4. Logical/Business Test

- [ ] Turning the phone-permission switch off shows the warning banner on the notifications screen and in the inbox.
- [ ] The language screen reachable while signed out (from sign-in) still works and does not require a session.
