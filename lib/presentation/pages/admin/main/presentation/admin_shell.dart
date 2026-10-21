import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/presentation/pages/admin/profile/profile.dart';
import 'package:eco_task/presentation/pages/admin/calendar/calendar.dart';
import 'package:eco_task/presentation/pages/admin/chat/chat.dart';
import 'package:eco_task/presentation/pages/admin/dashboard/dashboard.dart';
import 'package:eco_task/presentation/pages/admin/tasks/tasks.dart';
import 'package:eco_task/presentation/public/widgets/side_menu_shell.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';

/// Provides [MainBloc] (unread badge refresh). Signed-in UI of the admin role: a left menu whose sections are home, tasks, chat, calendar and profile, plus
/// the reports, team and expenses screens pushed from it.
class AdminShell extends StatelessWidget {
  /// Builds the admin shell.
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          MainBloc(repository: RepositoryProvider.of<NotificationsRepository>(ctx))..add(const MainStarted()),
      child: SideMenuShell(
        items: [
          SideMenuItem.section(TrWords.navHome.tr(), AppIcons.home, const DashboardScreen()),
          SideMenuItem.section(TrWords.navTasks.tr(), AppIcons.tasks, const TasksScreen()),
          SideMenuItem.section(
            TrWords.navChat.tr(),
            AppIcons.msg,
            const ChatsScreen(),
            badge: RepositoryProvider.of<ChatRepository>(context).unread,
          ),
          SideMenuItem.section(TrWords.navCalendar.tr(), AppIcons.cal, const CalendarScreen()),
          SideMenuItem.push(TrWords.navReports.tr(), AppIcons.chart, Routes.reports.path),
          SideMenuItem.push(TrWords.pfTeam.tr(), AppIcons.users, Routes.team.path),
          SideMenuItem.push(TrWords.pfExpenses.tr(), AppIcons.wallet, Routes.expenses.path),
          SideMenuItem.section(TrWords.navProfile.tr(), AppIcons.user, const AdminProfileScreen()),
        ],
      ),
    );
  }
}
