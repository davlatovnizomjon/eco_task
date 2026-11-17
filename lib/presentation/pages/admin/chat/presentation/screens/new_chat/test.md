# New chat and new group (admin) — Test Plan

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

- [ ] New chat: search, tap “Yangi guruh” (opens the group screen), tap a person (opens or reuses the direct chat). New group: type a name, tick members (chips appear above, tap a chip to remove), “Hammasini tanlash”, create.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Contacts are split into “Xodimlar” and “Mijozlar” captions with the role as subtitle; the group screen shows the counter “Xodimlar · N ta tanlandi” and round check marks; the “Yaratish” action is gray until a name and at least one member exist.
- [ ] Boards 3.2 / 3.3: the new-chat list shows people with a role pill under the name (“Yangi guruh” row on top); the new-group page has the camera tile with the name field, chosen-people chips with an “x”, a searchable list with round checks and “Hammasini tanlash”, and the “Guruh yaratish” button pinned at the bottom (enabled once a name and a member exist). Photo upload is not built.

## 4. Logical/Business Test

- [ ] Creating a group opens its conversation in place of the form; opening a direct chat twice reuses the same conversation.
