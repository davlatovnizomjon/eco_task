import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/pages/admin/admin.dart' as admin;
import 'package:eco_task/presentation/pages/auth/auth.dart';
import 'package:eco_task/presentation/pages/client/client.dart' as client;
import 'package:eco_task/presentation/pages/manager/manager.dart' as manager;
import 'package:eco_task/presentation/pages/worker/worker.dart' as worker;

import 'entity/routes.dart';

/// Key of the root navigator, so a dialog or a redirect can navigate without
/// a screen's own context.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Screens a signed-out user may open.
final _guestPaths = {Routes.signIn.path};

/// Builds the app router.
///
/// [session] is both the redirect's source of truth and its trigger: the router
/// listens to its `user` notifier, so signing in or out moves the app between
/// the sign-in screen and the home with no manual navigation anywhere.
///
/// Every screen is a URL-addressable route (see `NAVIGATION_MAP.md`), so any
/// feature can push any detail screen with `context.push(Routes.x.path)`.
GoRouter buildRouter(SessionRepository session) {
  /// First screen of a launch: home with a restored session, otherwise sign-in.
  final initialLocation = session.isGuest ? Routes.signIn.path : Routes.home.path;

  /// Whether the signed-in role's UI serves [r].
  bool serves(Routes r) => switch (session.role) {
    UserRole.owner => admin.adminRoutes.contains(r),
    UserRole.assistant => manager.managerRoutes.contains(r),
    UserRole.worker => worker.workerRoutes.contains(r),
    UserRole.client => client.clientRoutes.contains(r),
    null => false,
  };

  /// Declares the route [r]; its screen comes from the signed-in role's own UI folder, and a role that does
  /// not serve [r] is sent home.
  GoRoute route(Routes r) => GoRoute(
    path: r.path,
    redirect: (_, _) => serves(r) ? null : Routes.home.path,
    builder: (_, state) => switch (session.role!) {
      UserRole.owner => admin.adminScreen(r, state),
      UserRole.assistant => manager.managerScreen(r, state),
      UserRole.worker => worker.workerScreen(r, state),
      UserRole.client => client.clientScreen(r, state),
    },
  );
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: session.user,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (session.isGuest) return _guestPaths.contains(location) ? null : Routes.signIn.path;
      // Clients are served by the Telegram bot; the only screens they may see are the notice and settings.
      if (session.role == UserRole.client) {
        final here = Routes.values.where((r) => r.path == location);
        return here.isNotEmpty && client.clientRoutes.contains(here.first) ? null : Routes.clientBot.path;
      }
      if (location == Routes.signIn.path) return Routes.home.path;
      return null;
    },
    routes: [
      GoRoute(path: Routes.signIn.path, builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: Routes.home.path,
        builder: (_, _) => switch (session.role!) {
          UserRole.owner => const admin.AdminShell(),
          UserRole.assistant => const manager.ManagerShell(),
          UserRole.worker => const worker.WorkerShell(),
          UserRole.client => const client.ClientScreen(),
        },
      ),
      for (final r in Routes.values)
        if (r != Routes.signIn && r != Routes.home) route(r),
    ],
  );
}
