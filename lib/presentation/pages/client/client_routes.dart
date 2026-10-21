import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'main/main.dart';
import 'settings/settings.dart';

/// Routes the client UI serves; any other path is redirected home by the router.
const clientRoutes = <Routes>{
  Routes.clientBot,
  Routes.settingsLanguage,
  Routes.settingsAppearance,
  Routes.settingsNotifications,
};

/// Builds the client UI's screen for [route] ([s] carries its path and query parameters).
Widget clientScreen(Routes route, GoRouterState s) {
  return switch (route) {
    Routes.clientBot => const ClientScreen(),
    Routes.settingsLanguage => const LanguageSettingsScreen(),
    Routes.settingsAppearance => const AppearanceScreen(),
    Routes.settingsNotifications => const NotificationSettingsScreen(),
    _ => throw StateError('The client UI has no screen for $route'),
  };
}
