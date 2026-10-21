# Navigation map — Eco Tasks

Router: `lib/presentation/routes/coordinator.dart` (`go_router`, paths in `entity/routes.dart`).
Redirect: guests stay on the sign-in screen; signed-in users are moved off it to `/home`. Each role owns its UI folder
(`pages/admin|manager|worker|client`) with a route table `<role>_routes.dart` (`<role>Routes` = paths it serves,
`<role>Screen(route, state)` = its screen); the router picks the table by the signed-in role and sends a role home
for a path it does not serve. The selected section of a role shell is `homeTab` (`routes/home_tab.dart`), not a route.

`lib/presentation/pages/` holds ONLY `auth/` (shared) and the four role folders. Every role folder has `main/` (the
left-drawer shell + its bloc) and its own copy of each feature it uses (each with bloc, screens, `test.md`).

Screens
 ├─ AuthScreen [Path: '/sign-in'] (auth/presentation/auth_screen.dart)
 ├─ Home [Path: '/home'] — `<role>/main/presentation/<role>_shell.dart`
 │   ├─ AdminShell (admin/main): dashboard/, tasks/, chat/, calendar/, profile/ sections; menu pushes reports/, team/, expenses/
 │   ├─ ManagerShell (manager/main): same sections as admin, own copies
 │   ├─ WorkerShell (worker/main): today/, my_tasks/, chat/, notifications/, profile/ sections; menu pushes calendar/, history
 │   └─ ClientScreen (client/main) [Path: '/telegram']: client_bot/ section; menu pushes settings/
 Screens served per role (same paths, each role's own implementation):
 ├─ Boss (admin, manager): '/chat/new' '/chat/:id' '/tasks/:id/chat' '/reports' '/calendar' '/tasks/new' '/tasks/:id' '/tasks/:id/edit'
 │   '/review' '/expenses' '/expenses/:taskId/:expenseId' '/team' '/team/new' '/team/:id' '/team/:id/roles' '/status' '/progress'
 │   '/notifications' '/settings/language' '/settings/appearance' '/settings/notifications' '/settings/reminder'
 ├─ Worker: '/chat/new' '/chat/:id' '/tasks/:id/chat' '/calendar' '/tasks/:id' '/tasks/:id/expense' '/tasks/:id/submit'
 │   '/notifications' '/history' and the four '/settings/*'
 └─ Client: '/telegram' '/settings/language' '/settings/appearance' '/settings/notifications'

Sheets and dialogs are not routes: `TasksFilterDialog`, `AssigneePickerDialog`, `DueDateDialog`,
`TaskProgressDialog`, `TaskCommentDialog` (feature-local); `RejectDialog`, `PublicDialog` (`public/dialogs/`).
