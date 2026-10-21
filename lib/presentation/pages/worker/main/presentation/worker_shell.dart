import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/presentation/pages/worker/chat/chat.dart';
import 'package:eco_task/presentation/pages/worker/my_tasks/my_tasks.dart';
import 'package:eco_task/presentation/pages/worker/notifications/notifications.dart';
import 'package:eco_task/presentation/pages/worker/profile/profile.dart';
import 'package:eco_task/presentation/pages/worker/today/today.dart';
import 'package:eco_task/presentation/public/widgets/side_menu_shell.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';

/// Provides [MainBloc] (unread badge refresh). Signed-in UI of the worker: a left menu whose sections are today, my tasks, chat, notifications and profile,
/// plus the calendar and the task history pushed from it.
class WorkerShell extends StatelessWidget {
  /// Builds the worker shell.
  const WorkerShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          MainBloc(repository: RepositoryProvider.of<NotificationsRepository>(ctx))..add(const MainStarted()),
      child: SideMenuShell(
        items: [
          SideMenuItem.section(TrWords.navToday.tr(), AppIcons.home, const TodayScreen()),
          SideMenuItem.section(TrWords.navMyTasks.tr(), AppIcons.tasks, const MyTasksScreen()),
          SideMenuItem.section(
            TrWords.navChat.tr(),
            AppIcons.msg,
            const ChatsScreen(),
            badge: RepositoryProvider.of<ChatRepository>(context).unread,
          ),
          SideMenuItem.section(
            TrWords.navNotifs.tr(),
            AppIcons.bell,
            const NotificationsScreen(),
            badge: RepositoryProvider.of<NotificationsRepository>(context).unread,
          ),
          SideMenuItem.push(TrWords.navCalendar.tr(), AppIcons.cal, Routes.calendar.path),
          SideMenuItem.push(TrWords.pfHistory.tr(), AppIcons.history, Routes.history.path),
          SideMenuItem.section(TrWords.navProfile.tr(), AppIcons.user, const WorkerProfileScreen()),
        ],
      ),
    );
  }
}
