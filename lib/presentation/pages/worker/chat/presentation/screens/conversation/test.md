# Conversation (worker) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ChatRepository.getConversation` — GET `conversations/{id}/`

- [ ] Success: own conversation id → 200 with the payload; the parsed model matches it.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`.
- [ ] Foreign or unknown id → the same 404 `not_found` (no way to probe ids).

### `ChatRepository.getMessages` — GET `conversations/{id}/messages/?limit=30&before=`

- [ ] Success: 200 with `{results (newest first), has_more}`; the screen shows them oldest first.
- [ ] Parameters change the result: `before=<id>` returns only older messages; `limit` above 100 is clamped; a non-integer `before` → 400 `invalid_query`.
- [ ] `has_more` is false on the last page and the “older messages” button disappears.

### `ChatRepository.sendMessage` — POST `conversations/{id}/messages/`

- [ ] Success: `{body, client_msg_id}` → 201 with the stored message; the same `client_msg_id` again → 200 with the SAME message (no duplicate).
- [ ] Parameter errors: empty or over-4000-character body → 400 `invalid_message`, shown in the shared dialog.

### `ChatRepository.markRead` — POST `conversations/{id}/read/`

- [ ] Success: `{message_id}` → 200 `{last_read_message_id}`; a smaller id never moves the marker back.

### `ChatRepository.openTaskChat` — POST `conversations/` with `{kind: TASK, task}`

- [ ] Success: a task the user can see → 201 and the same conversation on every call; an invisible task → 404.

### WebSocket `ws(s)://host/ws/chat/{id}/` (subprotocols `bearer, <token>`)

- [ ] Connect: valid token and access → `presence.snapshot`; no/invalid token → close 4401; no access → close 4403; more than the per-user limit → 4429.
- [ ] `message.send` → every participant gets `message.new`; the sender also gets `message.ack` with the same `client_msg_id`; a repeated `client_msg_id` yields `duplicate: true` and no new row.
- [ ] `message.read` → others get `message.read`; `ping` → `pong`; unknown type / invalid JSON / oversized frame → `error` or close 1009.
- [ ] Access withdrawn (worker unassigned from the task) → `revoked` and close 4403 within a second.
- [ ] More than `CHAT_MESSAGES_PER_MINUTE` sends → `error: rate_limited`.

## 2. Mobile/Web Integration Test

- [ ] Open from the list, a task's chat action or a new chat; send, receive live, retry a failed message, load older messages, leave while the socket reconnects.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] The bar centres the conversation name with a green “onlayn” / “N a’zo” line; messages sit on the page background, own bubbles are green and carry the time and delivery marks (clock, check, double check when read); day captions (Bugun, Kecha, date) separate days.
- [ ] The input bar has a rounded multi-line field and a round green send button above the gesture area; the offline hint appears above it when the socket is down.
- [ ] Long press on a message (not pending or deleted) opens the actions sheet: 11 quick emojis (the chosen one highlighted; tapping it again removes it), copy (toast), edit (own only), pin / unpin, delete (own, or any for staff, after the confirm dialog).
- [ ] Edited messages show “tahrirlandi” beside the time and the new text; deleted ones show the italic “Xabar o‘chirildi” and lose their reactions; reaction chips under a bubble show emoji + count, the caller's own highlighted, and a tap toggles it.
- [ ] The pinned message shows in a banner under the bar (green caption, one line, “x” clears); deleting the pinned message clears it; a pin changed by another member arrives live (`conversation.pinned`), edits and reactions arrive as `message.updated`.
- [ ] Edit mode: the input shows “Xabarni tahrirlash” with an “x”; sending saves the edit (unchanged text sends nothing).
- [ ] Tapping the title opens the info page of a direct or group chat (not for task chats).
- [ ] Long press → “Javob berish”: a reply bar with the quoted author and text appears above the input (“x” closes it); the sent bubble shows the quote card; `reply_to` goes over the socket and REST; the quote of a deleted message reads “Xabar o‘chirildi”.
- [ ] Clip button: camera / gallery / document sheet; the file uploads (`POST files/`, thin progress line) and is sent as its own message with `attachment_id`; photos open in `PhotoViewer`, documents in `DocumentViewer`.
- [ ] Empty input shows a mic: holding records a voice note (timer, slide left cancels, under 1 s is dropped), releasing sends it; tapping the mic switches it to the camera (video circle) whose long press opens the front camera (max 60 s); bubbles show a play button with waveform for voice notes and a 180 px round player for circles. Needs a device: microphone/camera permissions, playback.

## 4. Logical/Business Test

- [ ] Sending is optimistic and de-duplicated by `client_msg_id`; a failed message can be retried by tapping it.
