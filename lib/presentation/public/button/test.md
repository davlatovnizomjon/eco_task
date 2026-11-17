# Button (PrimaryButton) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

- [ ] Not applicable: the button calls no endpoint and owns no repository or bloc.

## 2. Mobile/Web Integration Test

- [ ] The sign-in screen's “Kirish →” button is a `PrimaryButton`: tapping it submits the form; while the request runs it shows a spinner and “Kirilmoqda…”, drops the arrow and ignores further taps.
- [ ] After the request ends (success or failure) the button returns to “Kirish →” and taps work again.

## 3. UI Test

- [ ] It is full width, 48 px tall, with 12 px corners, the brand green fill and an on-primary label (15 px, semibold); the optional trailing icon is 18 px, 8 px after the label.
- [ ] Loading state: an 18 px spinner, 8 px before the label; the label is `loadingText` (or `text` when none is given).
- [ ] Pressing the button shows the standard `InkWell` splash and highlight over the green fill, and hovering with a pointer (web, desktop) shows the hover tint; while loading there is no splash.
- [ ] Disabled (`onPressed: null`): the fill is a washed-out green (the brand green at 40% over the screen background), the label and trailing icon are soft white (92% in light, 60% in dark), tapping does nothing and there is no splash or hover tint; a loading button is NOT drawn disabled (it keeps the full green).
- [ ] Light and dark themes both read correctly; long translated labels stay on one line without overflow at 320 px width.

## 4. Logical/Business Test

- [ ] `isLoading: true` never calls `onPressed`, even on repeated taps.
- [ ] Without `trailingIcon` no icon and no extra gap is drawn.
