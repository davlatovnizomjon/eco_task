# Chat (admin list) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ChatRepository.getConversations` — GET `conversations/`

- [ ] Success: a signed-in session → 200 with a JSON array; each row has `id`, `kind` (`DIRECT|GROUP|TASK`), `title`, `task`, `unread_count`, `last_message` (nullable) and `members`; the parsed `ConversationModel` matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: only conversations the user belongs to (direct/group) or whose task the user can see; sorted by newest message; `unread_count` counts only messages from others newer than the user's read marker; the sum equals the tab badge.
- [ ] Task chats of tasks the user lost access to (unassigned worker) disappear from the list.
- [ ] Cached-first: reopening the tab shows the cached list immediately, then the fresh list replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` (`MockChat`) and the live API (`AppConfig.useMockData`); the JSON shape is the backend's in both.

## 2. Mobile/Web Integration Test

- [ ] Open the tab, pull to refresh, tap “new group” and “new chat” actions, switch Hammasi / Guruhlar / Xodimlar / Mijozlar, open a conversation and return (the list refreshes).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Groups and task chats appear under “Guruhlar”, direct chats under “Shaxsiy”; a direct chat with a client carries a “Mijoz” chip; unread chats show a bold name, a green time and a green counter; own last messages show a check.

## 4. Logical/Business Test

- [ ] The Xodimlar / Mijozlar switch filters direct chats by the other member's role; the unread total on the tab bar matches the sum of the counters.
