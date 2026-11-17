# Chat info (admin)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ChatRepository.getConversation` — GET `conversations/{id}`; `updateConversation` — PATCH; `removeMember` — DELETE `conversations/{id}/members/{me}/`

- [ ] Success: members with roles, `muted`; PATCH `{muted}` flips only the caller's switch.
- [ ] Auth error: 401 → `UnAuthorizedResponse`; a foreign id → 404.
- [ ] Leaving a group: 204; afterwards the group is gone from the list and its socket is revoked.

## 2. Mobile/Web Integration Test

- [ ] Run with `AppConfig.useMockData = true` and against the live API; pull to refresh; retry after an error.

## 3. UI Test

- [ ] Boards 3.4 info, 3.5 profile, 3.5 muted: direct chat shows a 96 px avatar, name, “Xabar” and “Ovozsiz / Ovozni yoqish” buttons, phone, role and active tasks; a muted chat shows “Bildirishnomalar o‘chirildi”; a group shows the tile, “N a’zo”, members with role pills, the pencil (staff only) and the red “Guruhdan chiqish” row with its confirm dialog.
- [ ] No overflow at 320 px and 768 px; light and dark themes; uz, uz-Cyrl and ru without missing keys.

## 4. Logical/Business Test

- [ ] Muting stops inbox notifications for new messages of that conversation only for the caller.
- [ ] After leaving, the router goes home and the group is no longer listed.
