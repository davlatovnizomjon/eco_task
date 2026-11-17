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
 │   ├─ AdminShell (admin/main): floating bottom tab bar (`FloatingTabBar`) with five sections — dashboard/ (Asosiy),
 │   │   tasks/ (Vazifa), chat/ (centre call-to-action slot), reports/ (Hisobot), profile/ (Profil); every other screen is pushed
 │   ├─ ManagerShell (manager/main): the same floating bottom tab bar and five sections as the admin (its own copy of every
 │   │   feature); every other screen is pushed
 │   ├─ WorkerShell (worker/main): the same floating bottom tab bar as the admin — dashboard/ (Asosiy), tasks/ (Vazifa), chat/, reports/ (Statistika), profile/
 │   └─ ClientShell (client/main): floating bottom tab bar — tasks/ (Buyurtmalar), notifications/ (Xabarlar), chat/, the "Buyurtma" slot (opens '/tasks/new', no section) and profile/
 Screens served per role (same paths, each role's own implementation):
 ├─ Admin: '/reports/:kind' (StatsScreen, reports/…/stats) '/my-tasks/:id' (MyTaskScreen, dashboard/…/my_task) '/my-tasks/:id/notes' (TaskNotesScreen) '/chat/new' '/chat/group' '/chat/:id' '/chat/:id/info' (ChatInfoScreen) '/chat/:id/edit' (GroupEditScreen) '/call/:id' (CallScreen; `new?conversation=&kind=` starts one, an id shows a ringing/live call) '/tasks/:id/chat' '/today' '/rating' '/clients' '/profile/edit'
 │   '/profile/login' '/tasks/new' '/tasks/:id' '/tasks/:id/edit'
 │   '/team' '/team/new' '/team/:id' '/team/:id/tasks' '/notifications' — language and theme are bottom sheets of the profile tab
 ├─ Manager: the admin's screen set without the owner-only parts — '/reports/:kind' (tasks, mine, clients, staff only) '/my-tasks/:id' '/my-tasks/:id/notes' '/chat/new' '/chat/group' '/chat/:id' '/chat/:id/info' '/chat/:id/edit' '/call/:id' '/tasks/:id/chat' '/today' '/rating' '/clients' '/profile/edit'
 │   '/profile/login' '/tasks/new' '/tasks/:id' '/tasks/:id/edit'
 │   '/team' (all / staff tabs) '/team/new' (staff role only) '/team/:id' '/team/:id/tasks' '/notifications' — language and theme are bottom sheets of the profile tab
 ├─ Worker: the admin's own-task/chat/call/notification screens only — '/tasks/:id' and '/my-tasks/:id' (both MyTaskScreen) '/my-tasks/:id/notes' '/today' '/chat/new' '/chat/group' '/chat/:id' '/chat/:id/info' '/chat/:id/edit' '/call/:id' '/tasks/:id/chat' '/profile/edit' '/profile/login' '/notifications'; the fourth tab is "Statistika" (StatsScreen, kind `mine`)
 └─ Client: '/chat/:id' '/chat/:id/info' '/call/:id' '/tasks/new' (3-step order wizard) '/tasks/:id' (order details) '/tasks/:id/edit' '/profile/edit' '/profile/login' '/notifications' (also the second tab)

Sheets and dialogs are not routes: `TasksFilterDialog`, `AssigneeFilterDialog`, `TaskAssigneesDialog`, `DueDateDialog`, `RoleFilterSheet`,
`LanguageSheet`, `ThemeSheet`, `TaskFailSheet`, `MapsSheet`, `MessageActionsSheet`, `MemberPickerSheet`, `SupportSheet` (admin and manager, feature-local); `TaskProgressDialog`, `TaskCommentDialog` (worker, feature-local);
`RejectDialog`, `PublicDialog`, `ConfirmDialog`, `ActionMenu`, `PhotoViewer`, `DocumentViewer`, `DateRangeDialog` (`public/dialogs/`).
