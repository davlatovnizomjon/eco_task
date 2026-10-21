# New chat — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ChatRepository.getContacts` — GET `conversations/contacts/?q=`

- [ ] Success: 200 with brief users (`id`, `username`, `full_name`, `role`); never `password`, `is_superuser` or tokens.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`.
- [ ] Values: staff (admin, manager) get everyone but themselves; a worker or client gets staff only; inactive users are absent.
- [ ] Parameters change the result: `q` filters by login and full name (case-insensitive); a query nobody matches returns an empty list.

### `ChatRepository.openDirect` — POST `conversations/` with `{kind: DIRECT, user}`

- [ ] Success: 201 with the conversation; opening it again (from either side) returns the same id.
- [ ] Rules: worker ↔ worker, worker ↔ client, client ↔ client and writing to oneself → 403 `forbidden`; an unknown user → 404.

### `ChatRepository.createGroup` — POST `conversations/` with `{kind: GROUP, title, member_ids}`

- [ ] Success: a boss → 201; the creator is a member even when not listed.
- [ ] Rules: worker/client → 403; a missing title → 400 naming the field.

## 2. Mobile/Web Integration Test

- [ ] As a boss: search a person, tap, land in the (reused) chat; group tab: name it, tick people, create, land in it. As a worker/client: only the direct tab exists and only staff are listed.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live backend.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Search types without lag, out-of-order answers never overwrite a newer query's list; ticked people show a filled check; the create button is disabled until a title and one person are set.
- [ ] Empty result shows the “nobody found” view; a load failure shows the retry view.

## 4. Logical/Business Test

- [ ] Double-tapping a person opens one chat, not two; the screen replaces itself with the conversation so Back returns to the list.
