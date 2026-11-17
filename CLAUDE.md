# Eco Tasks — project instructions

Flutter app for task coordination in a plant-nursery company (roles: admin = backend OWNER, manager = backend ASSISTANT, worker, client).
Design handoff: HTML boards with tokens in light/dark; the Flutter theme maps 1:1 (`lib/constants/theme/app_theme.dart`).

## Conventions (the skills in `skills/` win over everything below)

- Follow `skills/flutter-project-rules`, `skills/flutter-ui-bloc`, `skills/navigation-map`, `skills/style-governor`
  and `skills/use-mock-data`; project-specific decisions are in `.rules/architecture.md`.
- Backend (`backend/`, Django + DRF): follow `skills/django-project-rules`, `skills/django-api-endpoint` and
  `skills/django-testing`; for the Telegram bot (`telegram-bot/`) follow `skills/telegram-bot-rules`. Skills live in `.claude/skills/` (`skills/` is a symlink to it).
- Every feature and sub-feature keeps `test.md` + `test_uz.md`; both are written/updated in the same change.
- Comments are English only (the Uzbek `test_uz.md` and UI strings are the only exceptions).
- Do not run tests/analyzer/the app unless the user asks (see `flutter-ui-bloc`).

## Where things live

- UI per role: `lib/presentation/pages/` holds ONLY `auth/` (shared) and `{admin,manager,worker,client}/`. Each role folder
  has `main/` (left-drawer shell via `SideMenuShell`; the admin uses the floating bottom `FloatingTabBar` instead), its own route table `<role>_routes.dart` and its own COPY of every
  feature it uses (chat, tasks, profile, ...). A change for one role is made in that role's folder only; do not import
  one role's folder from another.

- Icons: SVG in `assets/icons/`, constants in `lib/constants/res/app_icons.dart`, drawn with `AppIcon`.
- Fonts: Onest and Unbounded (variable TTF) in `assets/fonts/`; brand mark in `assets/images/`.
- Translations: the app is Uzbek-only (Latin) — one file, `assets/translations/uz.json`; `TrWords` (`lib/constants/res/translate.dart`)
  is generated from it — add a key to `uz.json`, then extend `TrWords`. There is no language switcher.
- Backend: Django API in `backend/` (Swagger UI at `/api/docs/`, schema at `/api/schema/`). The app talks to it through
  `lib/infrastructure/common/backend_dio_client.dart` (`flutter run --dart-define=API_HOST=http://localhost:8000`;
  Android emulator: `http://10.0.2.2:8000`).
- Clients: use the app's own client UI (`pages/client/`: orders, notifications, chat with the dispatcher, 3-step order wizard,
  profile; `ClientShell`) and may also use the Node.js Telegram bot in `telegram-bot/` (`npm test`, see its README) against the same
  REST API. Backend requests API: `backend/apps/client_requests/`.
- Mock backend: `lib/infrastructure/common/mock_dio_client.dart` + `mock_json_data/` (switch: `AppConfig.useMockData`,
  `--dart-define=USE_MOCK_DATA=true`).
- Demo accounts (password `1234`): `jamshid` (admin), `malika` (manager), `boris` (worker), `gulnora` (client).
