# Notifications (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `NotificationsRepository.getInbox` — GET `notifications?group=…`

- [ ] Success: `all`, `unread`, `review`, `deadlines`, `expenses` → 200 with a paged list with `unread`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: `unread` equals the number of entries with `isRead = false`; every kind renders with its own icon, color and localized title/body.
- [ ] Paging: opening the list issues exactly ONE request for page 1 (`pageSize` = the repository constant); the next page is requested only when scrolling near the end; pull-to-refresh reloads page 1 and resets the list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.

### `NotificationsRepository.markRead` — POST `notifications/read`

- [ ] Success: one id and no id (all) → 200 with the entries become read and the badge decreases; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.

## 2. Mobile/Web Integration Test

- [ ] Open from the dashboard bell; switch the chips (Hammasi, O‘qilmagan N, Tekshiruv, Muddatlar, Xarajatlar), tap “O‘qildi” (mark all read), tap a row (marks it read and opens review → tasks tab, expense → expenses, request → clients).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Boards 1.14–1.20: two tabs (Hammasi / O‘qilmagan); a bordered card per entry with a bold title, green time and dot while unread and a two-line message; tapping a card marks it read and opens a sheet with the whole message (and “Ochish” when the entry points at a screen); the checks action in the bar is dimmed when nothing is unread; empty (all / unread) and error states with the matching tile and retry.

## 4. Logical/Business Test

- [ ] The bell badge and the unread tab stay in sync after reading; “mark all read” empties the unread tab at once.
