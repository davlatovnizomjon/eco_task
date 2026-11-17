# App update gate — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `AppUpdateRepository.check` — GET `app-version/?platform=android|ios`

- [ ] Success: the installed version is lower than `latest_version` and `force_update` is false → `UpdateNeed.optional`; `title` and `subtitle` are carried into the result (empty strings when absent).
- [ ] Success: the installed version is lower and `force_update` is true → `UpdateNeed.required`.
- [ ] Values: the installed version equals or exceeds `latest_version` → `UpdateNeed.none`, even when `force_update` is true.
- [ ] Values: `1.2` equals `1.2.0`; `1.10.0` is newer than `1.9.9` (numeric, not text, comparison).
- [ ] Platform: web and desktop builds send no request and report `UpdateNeed.none`.
- [ ] Not found: the backend answers 404 (`release_not_found`) → the check fails silently and the app is not blocked.
- [ ] Offline / timeout / 4xx: the check fails silently, the previous result is kept and the app is not blocked.
- [ ] Maintenance flag: `is_maintenance: true` in the answer raises the maintenance wall (as a 5xx does); `false` (or the field missing) lowers it and the app is shown; the update dialogs are not offered while the wall is up and come back afterwards if still due, without stacking a second copy of one still open underneath.
- [ ] Server error: a 5xx answer (`ServerErrorResponse`) sets `maintenance` and raises the maintenance wall; a later successful answer lowers it again.
- [ ] No token: the request carries no bearer token and works before sign-in; an expired token never triggers a refresh or logout here.
- [ ] Mock/live parity: with `AppConfig.useMockData` the mock answers a version older than any build, so no prompt appears.

## 2. Mobile/Web Integration Test

- [ ] When the backend sends `title` / `subtitle` the dialog shows exactly that wording; when they are empty it falls back to the app's own text (“Yangi versiya mavjud” and the two versions).
- [ ] Launch with an optional update: after the first frame the dialog “Yangi versiya mavjud” shows both versions; “Yangilash” opens the store link, “Keyinroq” closes it.
- [ ] After “Keyinroq” the dialog does not return on resume for the same release; publishing a newer release shows it again.
- [ ] Launch with a mandatory update (`force_update` true): the same native dialog appears with only the “Yangilash” button (no “Keyinroq”); “Yangilash” opens the store and the dialog stays; the Android back button and a tap outside do not close it. With `force_update` false the dialog has both buttons.
- [ ] Return from the background after the backend flips `force_update` on: the mandatory dialog appears without a restart.
- [ ] An empty `store_url` shows the dialog, but the update button does nothing.
- [ ] Update the build to the published version: the dialog does not appear.
- [ ] `GET app-version/` answering 5xx at launch or on resume: the maintenance wall (“Texnik ishlar olib borilmoqda”) covers every screen — sign-in, any signed-in role's screens, pushed routes, sheets and dialogs. “Dispetcher bilan bog‘lanish” opens the dispatcher sheet ABOVE the wall (the wall has its own navigator, so the sheet is visible) and its close button / drag dismisses it. “Qayta urinish” shows a spinner while it asks again; when the endpoint answers normally the wall disappears and the app underneath is exactly as it was.
- [ ] While the wall is up a failing retry (still 5xx) keeps it; a retry that fails offline keeps it too (the wall never clears on a failure).

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long version strings and translated text truncate with an ellipsis.
- [ ] Light and dark themes both read correctly on the dialog.
- [ ] The maintenance wall matches the `4.1 Texnik ishlar olib borilmoqda` board: a 168 px double green halo behind an 84 px green rounded tile with the wrench glyph, 22 px semibold title, a 15 px message (max 300 px wide) and two full-width buttons 8 px apart, 36 px above the bottom: the green “Qayta urinish” and the outlined “Dispetcher bilan bog‘lanish” (headset glyph), in light and dark.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The optional-update dialog is `showUpdateDialog` (`lib/helpers/update_dialog.dart`) and looks native: on iOS a frosted alert (centred title and message, “Keyinroq” / “Yangilash” side by side split by hairlines, “Yangilash” semibold); on Android a Material 3 dialog (green refresh icon, 24 px centred title, left-aligned message, right-aligned text buttons). Both span the screen width with 24 px margins on the left and right and match the `Update dialog` board in light and dark; pressing “Keyinroq” or “Yangilash” shows the standard ink splash/highlight (Material's default colours, not green) on both platforms; a long message scrolls instead of overflowing. With `force_update` true only “Yangilash” is shown and it fills the iOS button row / sits alone at the right on Android.
