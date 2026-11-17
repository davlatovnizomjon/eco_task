import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/domain/common/enums/call_kind.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'chat/chat.dart';
import 'notifications/notifications.dart';
import 'profile/profile.dart';
import 'tasks/tasks.dart';

/// Routes the client UI serves; any other path is redirected home by the router.
const clientRoutes = <Routes>{
  Routes.chat,
  Routes.chatInfo,
  Routes.call,
  Routes.profileEdit,
  Routes.loginChange,
  Routes.taskNew,
  Routes.taskDetail,
  Routes.taskEdit,
  Routes.notifications,
};

/// Builds the client UI's screen for [route] ([s] carries its path and query parameters). Orders are the app's
/// tasks, so the order details and the order form are the task screens.
Widget clientScreen(Routes route, GoRouterState s) {
  return switch (route) {
    Routes.chat => ConversationScreen(conversationId: s.pathParameters['id']!),
    Routes.chatInfo => ChatInfoScreen(conversationId: s.pathParameters['id']!),
    Routes.call => CallScreen(
      callId: s.pathParameters['id']!,
      conversationId: s.uri.queryParameters['conversation'] ?? '',
      kind: CallKind.fromJson(s.uri.queryParameters['kind']),
    ),
    Routes.profileEdit => const ProfileEditScreen(),
    Routes.loginChange => const LoginChangeScreen(),
    Routes.taskNew => const TaskFormScreen(),
    Routes.taskDetail => TaskDetailScreen(taskId: s.pathParameters['id']!),
    Routes.taskEdit => TaskFormScreen(editId: s.pathParameters['id']),
    Routes.notifications => const NotificationsScreen(tab: true),
    _ => throw StateError('The client UI has no screen for $route'),
  };
}
