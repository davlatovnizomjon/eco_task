import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'calendar/calendar.dart';
import 'chat/chat.dart';
import 'expenses/expenses.dart';
import 'notifications/notifications.dart';
import 'reports/reports.dart';
import 'review/review.dart';
import 'settings/settings.dart';
import 'tasks/tasks.dart';
import 'team/team.dart';

/// Routes the manager UI serves; any other path is redirected home by the router.
const managerRoutes = <Routes>{
  Routes.chatNew,
  Routes.chat,
  Routes.taskChat,
  Routes.reports,
  Routes.calendar,
  Routes.taskNew,
  Routes.taskDetail,
  Routes.taskEdit,
  Routes.review,
  Routes.expenses,
  Routes.expenseReview,
  Routes.team,
  Routes.memberForm,
  Routes.employee,
  Routes.roles,
  Routes.taskStatus,
  Routes.teamProgress,
  Routes.notifications,
  Routes.settingsLanguage,
  Routes.settingsAppearance,
  Routes.settingsNotifications,
  Routes.settingsReminder,
};

/// Builds the manager UI's screen for [route] ([s] carries its path and query parameters).
Widget managerScreen(Routes route, GoRouterState s) {
  return switch (route) {
    Routes.chatNew => const NewChatScreen(),
    Routes.chat => ConversationScreen(conversationId: s.pathParameters['id']!),
    Routes.taskChat => ConversationScreen(taskId: s.pathParameters['id']!),
    Routes.reports => const ReportsScreen(pushed: true),
    Routes.calendar => const CalendarScreen(pushed: true),
    Routes.taskNew => const TaskFormScreen(),
    Routes.taskDetail => TaskDetailScreen(taskId: s.pathParameters['id']!),
    Routes.taskEdit => TaskFormScreen(editId: s.pathParameters['id']),
    Routes.review => const ReviewScreen(),
    Routes.expenses => const ExpensesScreen(),
    Routes.expenseReview => ExpenseReviewScreen(
      taskId: s.pathParameters['taskId']!,
      expenseId: s.pathParameters['expenseId']!,
    ),
    Routes.team => const TeamScreen(),
    Routes.memberForm => MemberFormScreen(client: s.uri.queryParameters['client'] == '1'),
    Routes.employee => EmployeeScreen(userId: s.pathParameters['id']!),
    Routes.roles => RolesScreen(userId: s.pathParameters['id']!),
    Routes.taskStatus => const TaskStatusScreen(),
    Routes.teamProgress => const TeamProgressScreen(),
    Routes.notifications => const NotificationsScreen(pushed: true),
    Routes.settingsLanguage => const LanguageSettingsScreen(),
    Routes.settingsAppearance => const AppearanceScreen(),
    Routes.settingsNotifications => const NotificationSettingsScreen(),
    Routes.settingsReminder => const ReminderScreen(),
    _ => throw StateError('The manager UI has no screen for $route'),
  };
}
