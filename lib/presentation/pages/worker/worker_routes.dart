import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'calendar/calendar.dart';
import 'chat/chat.dart';
import 'my_tasks/my_tasks.dart';
import 'notifications/notifications.dart';
import 'settings/settings.dart';
import 'tasks/tasks.dart';

/// Routes the worker UI serves; any other path is redirected home by the router.
const workerRoutes = <Routes>{
  Routes.chatNew,
  Routes.chat,
  Routes.taskChat,
  Routes.calendar,
  Routes.taskDetail,
  Routes.expenseForm,
  Routes.resultSubmit,
  Routes.notifications,
  Routes.history,
  Routes.settingsLanguage,
  Routes.settingsAppearance,
  Routes.settingsNotifications,
  Routes.settingsReminder,
};

/// Builds the worker UI's screen for [route] ([s] carries its path and query parameters).
Widget workerScreen(Routes route, GoRouterState s) {
  return switch (route) {
    Routes.chatNew => const NewChatScreen(),
    Routes.chat => ConversationScreen(conversationId: s.pathParameters['id']!),
    Routes.taskChat => ConversationScreen(taskId: s.pathParameters['id']!),
    Routes.calendar => const CalendarScreen(pushed: true),
    Routes.taskDetail => TaskDetailScreen(taskId: s.pathParameters['id']!),
    Routes.expenseForm => ExpenseFormScreen(taskId: s.pathParameters['id']!),
    Routes.resultSubmit => ResultSubmitScreen(taskId: s.pathParameters['id']!),
    Routes.notifications => const NotificationsScreen(pushed: true),
    Routes.history => const MyTasksScreen(historyOnly: true),
    Routes.settingsLanguage => const LanguageSettingsScreen(),
    Routes.settingsAppearance => const AppearanceScreen(),
    Routes.settingsNotifications => const NotificationSettingsScreen(),
    Routes.settingsReminder => const ReminderScreen(),
    _ => throw StateError('The worker UI has no screen for $route'),
  };
}
