import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/domain/common/enums/call_kind.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'chat/chat.dart';
import 'dashboard/dashboard.dart';
import 'notifications/notifications.dart';
import 'profile/profile.dart';
import 'tasks/tasks.dart';

/// Routes the worker UI serves; any other path is redirected home by the router.
const workerRoutes = <Routes>{
  Routes.chatNew,
  Routes.groupNew,
  Routes.chat,
  Routes.chatInfo,
  Routes.groupEdit,
  Routes.taskChat,
  Routes.call,
  Routes.todayTasks,
  Routes.profileEdit,
  Routes.loginChange,
  Routes.taskDetail,
  Routes.myTask,
  Routes.myTaskNotes,
  Routes.notifications,
};

/// Builds the worker UI's screen for [route] ([s] carries its path and query parameters). A worker's task is always
/// the "my task" screen, whichever of the two task paths led there.
Widget workerScreen(Routes route, GoRouterState s) {
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
    Routes.profileEdit => const ProfileEditScreen(),
    Routes.loginChange => const LoginChangeScreen(),
    Routes.taskDetail || Routes.myTask => MyTaskScreen(taskId: s.pathParameters['id']!),
    Routes.myTaskNotes => TaskNotesScreen(taskId: s.pathParameters['id']!),
    Routes.notifications => const NotificationsScreen(),
    _ => throw StateError('The worker UI has no screen for $route'),
  };
}
