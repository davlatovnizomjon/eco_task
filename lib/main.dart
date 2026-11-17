import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'constants/app_config.dart';
import 'constants/constants.dart';
import 'infrastructure/common/backend_dio_client.dart';
import 'infrastructure/common/dio_client.dart';
import 'infrastructure/common/mock_dio_client.dart';
import 'infrastructure/common/mock_json_data/mock_chat_connection.dart';
import 'infrastructure/common/mock_json_data/mock_store.dart';
import 'infrastructure/repository/app_update_repository.dart';
import 'infrastructure/repository/call_repository.dart';
import 'infrastructure/repository/chat_repository.dart';
import 'infrastructure/repository/expenses_repository.dart';
import 'infrastructure/repository/files_repository.dart';
import 'infrastructure/repository/notifications_repository.dart';
import 'infrastructure/repository/reports_repository.dart';
import 'infrastructure/repository/legal_repository.dart';
import 'infrastructure/repository/login_lock_repository.dart';
import 'infrastructure/repository/session_repository.dart';
import 'infrastructure/repository/settings_repository.dart';
import 'infrastructure/repository/support_repository.dart';
import 'infrastructure/repository/tasks_repository.dart';
import 'infrastructure/repository/team_repository.dart';
import 'infrastructure/services/call_connection.dart';
import 'infrastructure/services/chat_connection.dart';
import 'infrastructure/services/local_store.dart';
import 'infrastructure/services/push_service.dart';
import 'infrastructure/services/secure_store.dart';
import 'infrastructure/services/telegram_service.dart';
import 'presentation/public/update_gate/update_gate.dart';
import 'presentation/routes/coordinator.dart';
import 'presentation/routes/entity/routes.dart';

/// Boots the app: restores the stored session and settings, wires the HTTP
/// client to the session, then hands everything to the widget tree.
///
/// Order matters — the session must be restored before `dioClient` exists,
/// because the client reads its token synchronously on every request.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TelegramApp.init();
  await EasyLocalization.ensureInitialized();

  final secure = await SecureStore.create();
  final local = await LocalStore.create();
  final session = SessionRepository(secure);
  dioClient = AppConfig.useMockData ? MockDioClient(session) : BackendDioClient(session);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz')],
      fallbackLocale: const Locale('uz'),
      path: 'assets/translations',
      child: EcoTasksApp(session: session, settings: SettingsRepository(local), loginLock: LoginLockRepository(local)),
    ),
  );
}

/// Root widget: owns the app-wide repositories (created once, disposed with the
/// app), provides them above the router, applies the active palette and mounts
/// the router.
class EcoTasksApp extends StatefulWidget {
  /// Session restored in `main`, shared with the HTTP client and the router.
  final SessionRepository session;

  /// Device settings restored in `main`.
  final SettingsRepository settings;

  /// Remembered sign-in lock restored in `main`.
  final LoginLockRepository loginLock;

  /// Builds the app root.
  const EcoTasksApp({super.key, required this.session, required this.settings, required this.loginLock});

  @override
  State<EcoTasksApp> createState() => _EcoTasksAppState();
}

/// Owns the repositories and the router; listens to the platform brightness.
class _EcoTasksAppState extends State<EcoTasksApp> with WidgetsBindingObserver {
  /// Data source of tasks; shared by every feature that reads or writes them.
  late final TasksRepository _tasks;

  /// Data source of expenses.
  late final ExpensesRepository _expenses;

  /// Data source of the staff and client directory.
  late final TeamRepository _team;

  /// Data source of the inbox and its reactive unread counter.
  late final NotificationsRepository _notifications;

  /// Data source of aggregated numbers.
  late final ReportsRepository _reports;

  /// Data source of conversations, history and the live chat link.
  late final ChatRepository _chat;

  /// Data source of calls and the personal live link that rings.
  late final CallRepository _calls;

  /// Source of the latest published app version.
  late final AppUpdateRepository _updates;

  /// Source of the dispatcher contacts shown on the sign-in screen.
  late final SupportRepository _support;

  /// Uploads and downloads of photos, documents and recordings.
  late final FilesRepository _files;

  /// Source of the terms of use and privacy policy shown on the sign-in screen.
  late final LegalRepository _legal;

  /// Push notifications (Firebase Cloud Messaging); null in mock mode.
  PushService? _push;

  /// The app router, created once: rebuilding it would drop the navigation stack.
  late final GoRouter _router;

  /// Palette last applied to the global theme, to detect changes.
  bool? _dark;

  @override
  void initState() {
    super.initState();
    _tasks = TasksRepository();
    _expenses = ExpensesRepository();
    _team = TeamRepository();
    _notifications = NotificationsRepository();
    _reports = ReportsRepository();
    _updates = AppUpdateRepository();
    _support = SupportRepository();
    _legal = LegalRepository();
    _files = FilesRepository();
    _chat = ChatRepository(
      connector: AppConfig.useMockData
          ? (id) =>
                MockChatConnection(conversationId: id, me: () => MockStore.instance.userForToken(widget.session.token)!)
          : (id) => WebSocketChatConnection(conversationId: id, token: () => widget.session.token),
    );
    _calls = CallRepository(
      connector: AppConfig.useMockData
          ? IdleCallConnection.new
          : () => WebSocketCallConnection(token: () => widget.session.token),
    );
    _router = buildRouter(widget.session);
    _router.routerDelegate.addListener(_syncBackButton);
    WidgetsBinding.instance.addObserver(this);
    if (!AppConfig.useMockData) {
      _push = PushService(
        session: widget.session,
        language: () => DioClient.language,
        onForeground: () => unawaited(_notifications.refreshUnread().catchError((_) {})),
        onOpen: _openFromPush,
      );
      widget.session.beforeSignOut = _push!.unregister;
      unawaited(_push!.start());
    }
  }

  /// Opens the screen a tapped push points at: its conversation, its task, or the inbox.
  void _openFromPush(Map<String, String> data) {
    if (widget.session.isGuest) return;
    final chat = data['conversation_id'];
    final task = data['task_id'];
    _router.push(
      chat != null
          ? Routes.chat.of(chat)
          : task != null
          ? Routes.taskDetail.of(task)
          : Routes.notifications.path,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.routerDelegate.removeListener(_syncBackButton);
    _tasks.dispose();
    _notifications.dispose();
    _chat.dispose();
    _calls.dispose();
    widget.session.dispose();
    widget.settings.dispose();
    super.dispose();
  }

  /// Shows Telegram's native back button whenever the router has a screen to
  /// pop, and routes its tap to the router (no-op outside Telegram).
  void _syncBackButton() => TelegramApp.setBackButton(visible: _router.canPop(), onBack: _router.pop);

  @override
  void didChangePlatformBrightness() => setState(() {});

  /// Marks every mounted element dirty so widgets that read the global [theme]
  /// repaint with the new palette without losing their state.
  void _rebuildAll() {
    void mark(Element element) {
      element.markNeedsBuild();
      element.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.session),
        RepositoryProvider.value(value: widget.settings),
        RepositoryProvider.value(value: widget.loginLock),
        RepositoryProvider.value(value: _tasks),
        RepositoryProvider.value(value: _expenses),
        RepositoryProvider.value(value: _team),
        RepositoryProvider.value(value: _notifications),
        RepositoryProvider.value(value: _reports),
        RepositoryProvider.value(value: _chat),
        RepositoryProvider.value(value: _calls),
        RepositoryProvider.value(value: _updates),
        RepositoryProvider.value(value: _support),
        RepositoryProvider.value(value: _legal),
        RepositoryProvider.value(value: _files),
      ],
      child: ValueListenableBuilder<AppSettings>(
        valueListenable: widget.settings.settings,
        builder: (context, settings, _) {
          // The stored mode wins; "system" follows the phone's brightness.
          final dark = settings.themeMode == ThemeMode.system
              ? WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark
              : settings.themeMode == ThemeMode.dark;
          if (_dark != null && _dark != dark) WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll());
          _dark = dark;
          theme.dark = dark;
          TelegramApp.setColors('#${(theme.background.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}');
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, _) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: TrWords.appName.tr(),
                theme: theme.data,
                routerConfig: _router,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: (context, child) => MediaQuery.withClampedTextScaling(
                  minScaleFactor: 1,
                  maxScaleFactor: settings.bigText ? 1.3 : 1,
                  child: UpdateGate(child: child!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
