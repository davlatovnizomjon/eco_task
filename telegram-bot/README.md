# Eco Tasks — Telegram bot (clients)

Node.js (>= 20) bot built with [grammY](https://grammy.dev). It is the **only** client-facing surface of Eco Tasks: the
mobile app no longer serves the `CLIENT` role (it shows a notice pointing here). The bot talks to the Django REST API
in `../backend` with the client's own bearer token, so every backend rule (visibility, 404-for-foreign-ids, throttles)
applies exactly as in the app.

## What a client can do

| Menu | Backend endpoints |
| --- | --- |
| 📝 New request (kind → title → details → address → date → time → confirm) | `POST /requests/` |
| 📋 My requests (card with status, executor, last messages; write a message) | `GET /requests/`, `GET /requests/{id}/`, `GET/POST /requests/{id}/messages/` |
| 💬 Chats (open, read the last messages, type to send, start a chat with staff) | `GET /conversations/`, `GET /conversations/contacts/`, `POST /conversations/`, `GET/POST /conversations/{id}/messages/`, `POST …/read/` |
| 🔔 Notifications (also pushed automatically) | `GET /notifications/?unread=true`, `POST /notifications/read/` |
| 🌐 Language (uz, uz-Cyrl, ru) · 🚪 Log out | `POST /auth/logout/` |

Sign-in: `/start` → language → login → password (the password message is deleted at once). Staff accounts are refused
and logged out again. The token is kept in `DATA_FILE` (mode 0600); an expired token (401) unlinks the chat and asks to
sign in again.

New messages and request updates arrive as notifications: every `POLL_SECONDS` the bot fetches each linked client's
unread notifications, sends them with an “Open” button and marks them read. (Chat message *bodies* are not part of a
notification; “Open” shows the last messages.)

## Run

```bash
cd telegram-bot
npm install
cp .env.example .env     # fill BOT_TOKEN (from @BotFather) and API_BASE_URL
set -a; . ./.env; set +a
npm start                # long polling; no public URL needed
npm test                 # unit + handler tests, no network
```

Backend side: `python manage.py seed_demo` creates `gulnora` (CLIENT) for local trials. Put the bot's @name into the
mobile build with `--dart-define=TELEGRAM_BOT=@your_bot`.

## Layout

```
src/config.js    env -> frozen config            src/bot.js       handlers: login, wizard, requests, chats, menu
src/api.js       REST client + error envelope    src/notifier.js  polling push of notifications
src/store.js     chat id -> token/lang (JSON)    src/i18n.js      all texts, 3 languages (parity is tested)
src/format.js    cards, dates, notification text src/index.js     wiring and graceful shutdown
```

## Notes and limits

* One process, long polling. For several instances switch to webhooks and replace `store.js` with a database (the rest
  of the bot only uses `get/all/update/unlink`).
* Conversation state (a half-filled request) is in memory; a restart only means pressing the button again.
* Photos/files and live typing are not supported; messages are plain text (no Markdown/HTML, so user text cannot inject markup).
