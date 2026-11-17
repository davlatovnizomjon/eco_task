# Eco Tasks

Workforce and task coordination app for the Eco ecosystem (Flutter). Four roles — admin, manager, worker, client — with
tasks, review/approval, expenses and payouts, a calendar, reports, client requests and a notifications inbox. Languages:
Uzbek (Latin) only; light and dark themes.

The app talks to the Django backend in `backend/` (API docs: `http://localhost:8000/api/docs/`). Run it with
`flutter run --dart-define=API_HOST=http://localhost:8000`, or fully offline on the built-in mock backend with
`flutter run --dart-define=USE_MOCK_DATA=true`. Tabs: Home/Today, Tasks, **Chat**, Calendar, More/Profile/Notifications.
In mock mode the demo accounts (password `1234`) are:
`jamshid` (admin), `malika` (manager), `boris` (worker), `gulnora` (client).

Clients use the app (orders, chat, calls) and may also use the Telegram bot in `telegram-bot/` (see its README).

See `CLAUDE.md`, `.rules/` and `lib/presentation/routes/NAVIGATION_MAP.md`.
