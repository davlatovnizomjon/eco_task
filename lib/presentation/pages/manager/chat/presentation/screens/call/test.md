# Call (manager)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `CallRepository.start` — POST `conversations/{id}/calls/`; `get` — GET `calls/{id}/`; `answer` / `decline` / `end` — POST `calls/{id}/{action}/`; `invite` — POST `calls/{id}/invite/`

- [ ] Success: `start` → 201 with `status` RINGING, the caller JOINED and every other member INVITED; `answer` → ACTIVE and `answered_at` set; `decline` by the only invitee of a direct call → DECLINED; `end` by the caller while ringing → CANCELED, afterwards → ENDED; `invite` adds group members as INVITED.
- [ ] Auth error: 401 → `UnAuthorizedResponse`; a call of a stranger → 404.
- [ ] Rules: a task chat → 400; a second call in a conversation that rings → 409 `call_in_progress`; nobody to call → 400; an unanswered call becomes MISSED after `CALL_RING_SECONDS`.
- [ ] Live link: `ws/me/` delivers `call.incoming|answered|declined|ended` and relays `call.signal` only between two people of the same live call.

## 2. Mobile/Web Integration Test

- [ ] Run against the live API with two devices: a direct voice call, a video call, a group call with three people, adding a fourth, declining, no answer, redial. On the mock backend (`AppConfig.useMockData`) the call opens active without real media.
- [ ] Minimizing the screen (back chevron) keeps the sound going; pressing the handset in the same chat returns to the call.

## 3. UI Test

- [ ] Boards 3.7 direct: outgoing “Chaqirilmoqda…”, incoming (red decline / green accept with the soft double ring), active (timer `mm:ss`), video (full-screen picture, small own picture, flip camera), declined (“Qo‘ng‘iroq rad etildi”, red) and no answer (“Javob bermadi”, amber) with the swipe-to-redial control and a close button.
- [ ] Boards 3.7 group: grid of tiles (two columns up to four people, three columns beyond), muted people show a red microphone, the title shows “N ishtirokchi · timer”, the “+” button opens the “Qo‘ng‘iroqqa qo‘shish” sheet with people who are not in the call, the “+N yana” / “orqaga” tiles page the grid, “X taklifni rad etdi” appears for three seconds, and the invitation screen shows the group tile, who invites and “N kishi suhbatda”.
- [ ] The handset in the chat header (direct and group chats, not task chats) starts a call.
- [ ] No overflow at 320 px and 768 px; uz, uz-Cyrl and ru without missing keys; the backdrop looks the same in light and dark mode.

## 4. Logical/Business Test

- [ ] Only the person who joins offers WebRTC connections, to everybody already in the call; a person who leaves is dropped from every other grid.
- [ ] A finished call shows its result only to the person who started it (declined / no answer); everyone else is returned to the chat.
- [ ] An incoming call opens the call screen from any screen of the signed-in shell; declining or the caller cancelling closes it.
