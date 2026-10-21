# Conversation — Test Plan

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

- [ ] Open from the list, from a task (chat icon in the task header) and right after creating a chat; send, receive, go back.
- [ ] Kill the network while the screen is open: the “reconnecting” banner appears, a message sent meanwhile goes out over REST, and after the network returns the socket reconnects and missed messages appear without duplicates.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` (scripted “Qabul qilindi 👍” reply) and again against the live backend.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The thread starts at the bottom with the newest message; own bubbles right in the brand color, others' left; group and task chats show author avatar and name; long words wrap and never overflow.
- [ ] Delivery marks: clock while sending, one tick when stored, two ticks when read; a failed message shows a red alert and “tap to retry”.
- [ ] The keyboard never covers the input; opening the keyboard keeps the newest message visible.

## 4. Logical/Business Test

- [ ] Sending the same text twice quickly creates two messages (different client ids); a network retry of ONE send never creates two.
- [ ] A message that arrives over the socket while its REST copy is also loaded appears once.
- [ ] Opening a conversation marks others' messages read once, and the list badge drops after returning.
