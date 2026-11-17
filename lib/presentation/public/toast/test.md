# Toast — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

- [ ] Not applicable: the toast calls no endpoint and owns no repository or bloc.

## 2. Mobile/Web Integration Test

- [ ] `showTopToast(context, ...)` from any screen shows the toast without that screen holding a `Stack` or placeholder widget; the sign-in screen's empty-field and wrong-credentials toasts go through it.
- [ ] The toast lives in the root overlay: it stays above bottom sheets and dialogs opened afterwards and survives a route change until its time runs out.
- [ ] A second toast shown while one is visible replaces the first at once (never two on screen); showing the same toast twice in a row shows it twice.
- [ ] Taps on whatever is under the toast (header buttons, fields) pass through it.
- [ ] The toast hides itself after 4 seconds (or the `duration` passed); it has no close button.

## 3. UI Test

- [ ] It matches the `Toast` board: a 36 px tinted round icon, a 15 px semibold title (weight 650), a 13 px message, 14 px right padding, a tone-coloured border (success, info, warning, error), 16 px corners and a soft shadow; in dark a deeper two-layer shadow.
- [ ] It sits 8 px under the status bar, 12 px from the left and right edges, and works with a notch and with the status bar hidden.
- [ ] It slides down from above the screen edge when it appears (about 320 ms) and slides back up out of sight when it leaves (about 260 ms).
- [ ] Long titles and messages wrap without overflow; light and dark themes both read correctly; Uzbek Latin, Uzbek Cyrillic and Russian texts all fit.

## 4. Logical/Business Test

- [ ] A toast whose screen was closed before its time ran out still disappears on schedule and leaves no overlay entry behind.
- [ ] Rapid repeated calls leave exactly one overlay entry at the end.
