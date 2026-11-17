import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/presentation/pages/manager/chat/chat.dart';
import 'package:eco_task/presentation/pages/manager/dashboard/dashboard.dart';
import 'package:eco_task/presentation/pages/manager/profile/profile.dart';
import 'package:eco_task/presentation/pages/manager/reports/reports.dart';
import 'package:eco_task/presentation/pages/manager/tasks/tasks.dart';
import 'package:eco_task/presentation/public/widgets/floating_tab_bar.dart';
import 'package:eco_task/presentation/public/widgets/incoming_call_listener.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';

import '../bloc/bloc.dart';

/// Provides [MainBloc] (unread badge refresh). Signed-in UI of the manager role: five sections (home, tasks, chat,
/// reports, profile) kept alive under a floating bottom tab bar; every other screen is pushed from them.
class ManagerShell extends StatelessWidget {
  /// Builds the manager shell.
  const ManagerShell({super.key});

  @override
  Widget build(BuildContext context) {
    final chatUnread = RepositoryProvider.of<ChatRepository>(context).unread;
    return IncomingCallListener(
      child: BlocProvider(
        create: (ctx) =>
            MainBloc(repository: RepositoryProvider.of<NotificationsRepository>(ctx))..add(const MainStarted()),
        child: ValueListenableBuilder<int>(
          valueListenable: homeTab,
          builder: (context, selected, _) {
            const sections = <Widget>[
              DashboardScreen(),
              TasksScreen(),
              ChatsScreen(),
              ReportsScreen(),
              ManagerProfileScreen(),
            ];
            final index = selected.clamp(0, sections.length - 1);
            return Scaffold(
              backgroundColor: theme.background,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(index: index, children: sections),
                  ),
                  FloatingTabBar(
                    selected: index,
                    onSelected: (i) => homeTab.value = i,
                    items: [
                      TabBarItem(icon: AppIcons.home, label: TrWords.navHome.tr()),
                      TabBarItem(icon: AppIcons.tasks, label: TrWords.dashTasksShort.tr()),
                      TabBarItem(icon: AppIcons.msg, label: TrWords.navChat.tr(), badge: chatUnread, cta: true),
                      TabBarItem(icon: AppIcons.chart, label: TrWords.dashReportShort.tr()),
                      TabBarItem(icon: AppIcons.user, label: TrWords.navProfile.tr()),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
