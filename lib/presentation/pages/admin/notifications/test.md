# Notifications inbox — Test Plan

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

- [ ] Create events as another role (submit a result, comment, plan a request) and see the matching inbox entries; opening one marks it read and, for boss review/expense entries, navigates to the queue.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Loading shows the shimmer placeholder cards (no spinner); an empty result shows the empty view; a failed first load shows the retry view and the retry button reloads.
- [ ] Pull-to-refresh works on a full list, a short list and the empty/error view (always-scrollable); the indicator completes when the network call finishes, not on the cached emit.
- [ ] The last row clears the system gesture bar (bottom inset is part of the scroll padding).
- [ ] Filter pills differ by role (boss: five, others: all/unread); entries are grouped Today / Yesterday / date; unread entries are bold with a dot; the permission-off banner links to Settings.

## 4. Logical/Business Test

- [ ] “Mark all read” zeroes the tab badge and the unread filter becomes empty.
