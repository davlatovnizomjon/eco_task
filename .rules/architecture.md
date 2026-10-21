# Project rules — architecture decisions

Project-specific decisions that refine (never weaken) the shared skills.

1. **Repositories are app-scoped.** Task, expense, team, notification, request and report repositories are shared by
   many features, so `EcoTasksApp` (`lib/main.dart`) owns them — created once in `initState`, disposed in `dispose`,
   provided in one `MultiRepositoryProvider` ABOVE the router. A feature screen therefore only provides its own bloc
   (`BlocProvider(create: (ctx) => XBloc(repository: RepositoryProvider.of<R>(ctx)))`) and never builds a repository.
   Because they sit above the Navigator, pushed routes and sheets can always read them (no `ProviderNotFoundException`).
2. **Screens are `go_router` routes.** Any feature may `context.push(Routes.x.path)` any detail screen; screens that
   need ids read them from path parameters (see `lib/presentation/routes/NAVIGATION_MAP.md`).
3. **Two interchangeable HTTP clients.** `AppConfig.useMockData` (`--dart-define=USE_MOCK_DATA=true`) picks
   `MockDioClient`; otherwise `BackendDioClient` talks to the Django API at `AppConfig.apiHost` (`--dart-define=API_HOST=`).
   `BackendDioClient` translates the app's own paths/bodies to the backend's through `BackendMapper` (status words,
   `full_name` → `name`, DRF pages → `PagedList`, history/comments → log/comments) so repositories, blocs and DTOs never see
   backend JSON. Chat uses the backend's shape natively and goes straight through. Features the backend lacks
   (expenses, requests, dashboard, reports, profile numbers) are answered by the mock store acting as the signed-in role.
   The role names follow the backend: `UserRole.owner` (UI label "Admin") and `UserRole.assistant` ("Menejer").
   **Mock backend sits behind `MockDioClient`.** `MockStore` holds typed models and answers with the same JSON the live
   API will; repositories and blocs are identical in mock and live mode.
4. **Paging and cache.** Every list screen requests one page (`pageSize` constant on the repository). `ApiCache` holds the
   first page per query; any mutation calls `ApiCache.invalidate()`.
5. **Theme.** `theme.dark` is set by the app root from the stored mode and the platform brightness; on change the root
   marks all elements dirty so widgets reading the global `theme` repaint without losing state.
6. **Chat is live.** `ChatRepository` (app-scoped) serves REST history and hands each conversation screen a
   `ChatConnection` (WebSocket `/ws/chat/<id>/`, token in the `bearer` subprotocol; the mock flavour is scripted).
   `ConversationBloc` sends optimistically with a `client_msg_id`, falls back to REST when the socket is down or silent,
   and de-duplicates by that id. The bottom-navigation chat badge is `ChatRepository.unread`.
7. **Clients live in Telegram.** The `CLIENT` role has no screens in the Flutter app: the router redirects it to
   `/telegram` (`ClientScreen` → `ClientBotScreen`, naming `AppConfig.telegramBot`). Everything a client does — service requests,
   chat with staff, notifications — happens in `telegram-bot/` (Node.js, grammY, long polling) against the same REST API
   with the client's own token. Service requests are the backend's `apps/client_requests` (staff manage them through
   `PATCH /requests/{id}/`).
8. **One UI folder per role.** `pages/` contains only `auth` and `admin` (OWNER), `manager` (ASSISTANT), `worker`,
   `client`. Each role has `main/` (left drawer shell, `public/widgets/side_menu_shell.dart`; `SideMenuItem.section` =
   in-shell section, `.push` = pushed route), its own copy of each feature it uses (own bloc/screens/tests; profile is
   `ProfileFrame` + the role's profile screen) and `<role>_routes.dart`, the route table the router consults by role.
   Roles never import each other; the duplication is deliberate so each UI evolves independently. `homeTab` is the
   selected section; keep the section order so indexes other screens assign (1 = tasks, 3 = calendar/notifications) hold.
9. **Formatting.** `analysis_options.yaml` sets `formatter.page_width: 120`.
