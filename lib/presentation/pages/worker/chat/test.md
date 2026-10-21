# Chat (conversation list) — Test Plan

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

- [ ] As each role open the Chat tab, open a conversation, send a message, go back: the row shows the new last message with “You: …” and the unread badge is cleared.
- [ ] Two devices/accounts: a message sent on one appears on the other's open conversation within a second and raises the other's list badge after a refresh.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live backend (`--dart-define=API_HOST=...`).

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Rows: avatar (person) or round tile (group/task), name, last message preview (bold while unread), relative time, unread badge; “+” in the app bar opens the new-chat screen.
- [ ] Shimmer while the first load runs; an empty list shows the empty view; a first-load failure shows the retry view; pull-to-refresh works on a full, a short and an empty list.

## 4. Logical/Business Test

- [ ] A client sees only conversations with staff and the task chats of their own tasks, never another client's.
- [ ] The tab badge equals the sum of `unread_count` and never goes negative after marking read.
