---
name: telegram-bot-rules
description: >-
  Conventions of the Eco Tasks Telegram bot (`telegram-bot/`, Node.js + grammY) that serves the CLIENT role. Use
  whenever you add or change a bot command, wizard step, menu button, text, notification handling or the bot's use of the
  REST API.
---

# Telegram bot rules

- The bot is the client's only surface. It never has its own business rules: it calls the Django REST API with the
  client's bearer token and shows what the API returns. New client capability = backend endpoint first
  (`django-api-endpoint`), then a bot handler.
- Plain text only (no `parse_mode`): user content must never be interpreted as markup. Never log tokens, passwords or
  message bodies; delete the password message right after reading it.
- Every user-facing string lives in `src/i18n.js` in ALL languages (uz, uz-Cyrl, ru) with identical keys and placeholders
  (`test/units.test.js` enforces it). Menu buttons are matched in every language via `allLangs(key)`.
- Flows (`flows` map in `src/bot.js`) are per chat id, in memory, and are ended by any menu button. Callback data is
  `prefix:value` and at most 64 bytes.
- API failures go through `guarded()`: 401 unlinks the chat, 0/5xx says the server is down, others show the backend
  `detail`. Do not add per-handler try/catch for this.
- Accounts are stored only through `src/store.js` (atomic write, mode 0600); never read the file elsewhere.
- Tests: `npm test` (node:test). Handler tests use `test/helpers.js` (`harness`) with a fake API and recorded Telegram
  calls — add one for every new flow. Run them only when asked.
- Comments in English; keep `README.md` (menu ↔ endpoint table) in sync.
