# Settings sheets: language and appearance (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

- [ ] No network endpoints: this feature only reads/writes local state (see sections 2–4).

## 2. Mobile/Web Integration Test

- [ ] The choice persists through `LocalStore` and is restored after an app restart: theme mode and notification switch; the language is remembered by `easy_localization`.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Both sheets open from the profile rows with a grab handle, a title and a close action; the active option is bold with a green check.
- [ ] Choosing the dark theme repaints the whole app at once, including the screens already open under the sheet.

## 4. Logical/Business Test

- [ ] Changing the language applies app-wide without a restart; the same choice is available while signed out from the sign-in screen.
