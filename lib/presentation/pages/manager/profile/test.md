# Profile (manager tab) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `SupportRepository.getContact` — GET `support/`

- [ ] Success: 200 → `phone` and `telegram` are parsed into `SupportContact`; the help sheet shows them.
- [ ] Not configured: 404 → `SupportContact.none`; the sheet shows “Dispetcher kontaktlari hali kiritilmagan.” and no rows.
- [ ] Auth error: missing/expired token → 401 → the session is cleared and the router returns to sign-in.
- [ ] Cached-first: reopening the tab uses the remembered contacts at once, then the fresh ones.

### `SessionRepository.clearSession` — POST `auth/logout`

- [ ] Success: the token is revoked remotely and the local session is cleared; offline, the local session is still cleared.

## 2. Mobile/Web Integration Test

- [ ] Open the edit screen from the pencil on the account card, the language, appearance and help sheets from their rows, toggle notifications, sign out (confirm) and sign in as another role.
- [ ] Help sheet: “Qo‘ng‘iroq qilish” opens the dialer, “Telegram orqali yozish” opens Telegram; both close the sheet.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches boards 5.1 and 5.3–5.5 of `Eco Tasks — mobile app` 1:1 in light and dark themes: the centred account card (84 px avatar with a soft ring, name, phone, role pill, pencil button), the settings card with 60 px rows and the red sign-out card.
- [ ] The settings card shows the current language, the current theme and “Yoqilgan” / “O‘chirilgan” next to the switch (the language row is kept on top of the board so the language stays changeable).
- [ ] Choosing a language or theme in its sheet applies at once, closes the sheet and updates the row value; the theme sheet marks the current choice with a filled round check.
- [ ] Sign-out dialog (5.5): red tile, title, explanation, “Bekor qilish” and a solid red “Chiqish” that spins while the session is being closed.

## 4. Logical/Business Test

- [ ] Sign-out always asks for confirmation first and clears the session, caches and the selected tab.
- [ ] The notification switch writes `SettingsRepository.setNotificationsAllowed` and survives an app restart.
- [ ] A help way without a value (no phone, or no Telegram) is hidden rather than shown empty.
