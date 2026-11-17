import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/domain/common/enums/call_kind.dart';
import 'package:eco_task/domain/common/enums/stats_kind.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'chat/chat.dart';
import 'dashboard/dashboard.dart';
import 'notifications/notifications.dart';
import 'profile/profile.dart';
import 'reports/reports.dart';
import 'tasks/tasks.dart';
import 'team/team.dart';

/// Routes the manager UI serves; any other path is redirected home by the router.
const managerRoutes = <Routes>{
  Routes.chatNew,
  Routes.groupNew,
  Routes.chat,
  Routes.chatInfo,
  Routes.groupEdit,
  Routes.taskChat,
  Routes.call,
  Routes.todayTasks,
  Routes.rating,
  Routes.clients,
  Routes.profileEdit,
  Routes.loginChange,
  Routes.taskNew,
  Routes.taskDetail,
  Routes.taskEdit,
  Routes.myTask,
  Routes.stats,
  Routes.myTaskNotes,
  Routes.team,
  Routes.memberForm,
  Routes.employee,
  Routes.employeeTasks,
  Routes.notifications,
};

/// Builds the manager UI's screen for [route] ([s] carries its path and query parameters).
Widget managerScreen(Routes route, GoRouterState s) {
  return switch (route) {
    Routes.chatNew => const NewChatScreen(),
    Routes.groupNew => const NewGroupScreen(),
    Routes.chatInfo => ChatInfoScreen(conversationId: s.pathParameters['id']!),
    Routes.groupEdit => GroupEditScreen(conversationId: s.pathParameters['id']!),
    Routes.chat => ConversationScreen(conversationId: s.pathParameters['id']!),
    Routes.taskChat => ConversationScreen(taskId: s.pathParameters['id']!),
    Routes.call => CallScreen(
      callId: s.pathParameters['id']!,
      conversationId: s.uri.queryParameters['conversation'] ?? '',
      kind: CallKind.fromJson(s.uri.queryParameters['kind']),
    ),
    Routes.todayTasks => const TodayScreen(),
    Routes.rating => const RatingScreen(),
    Routes.clients => const ClientsScreen(),
    Routes.profileEdit => const ProfileEditScreen(),
    Routes.loginChange => const LoginChangeScreen(),
    Routes.taskNew => const TaskFormScreen(),
    Routes.taskDetail => TaskDetailScreen(taskId: s.pathParameters['id']!),
    Routes.taskEdit => TaskFormScreen(editId: s.pathParameters['id']),
    Routes.stats => StatsScreen(kind: _statsKind(s.pathParameters['kind'])),
    Routes.myTask => MyTaskScreen(taskId: s.pathParameters['id']!),
    Routes.myTaskNotes => TaskNotesScreen(taskId: s.pathParameters['id']!),
    Routes.team => const TeamScreen(),
    Routes.memberForm => MemberFormScreen(
      client: s.uri.queryParameters['client'] == '1',
      editId: s.uri.queryParameters['edit'],
    ),
    Routes.employee => EmployeeScreen(userId: s.pathParameters['id']!),
    Routes.employeeTasks => EmployeeTasksScreen(userId: s.pathParameters['id']!),
    Routes.notifications => const NotificationsScreen(),
    _ => throw StateError('The manager UI has no screen for $route'),
  };
}

/// Statistics kind of a `/reports/:kind` path; the owner-only kinds (finance, managers) fall back to the task statistics.
StatsKind _statsKind(String? name) {
  final kind = StatsKind.fromName(name);
  return kind == StatsKind.finance || kind == StatsKind.managers ? StatsKind.tasks : kind;
}
