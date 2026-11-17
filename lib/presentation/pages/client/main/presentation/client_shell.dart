import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/presentation/pages/client/chat/chat.dart';
import 'package:eco_task/presentation/pages/client/notifications/notifications.dart';
import 'package:eco_task/presentation/pages/client/profile/profile.dart';
import 'package:eco_task/presentation/pages/client/tasks/tasks.dart';
import 'package:eco_task/presentation/public/widgets/floating_tab_bar.dart';
import 'package:eco_task/presentation/public/widgets/incoming_call_listener.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';

import '../bloc/bloc.dart';

/// Provides [MainBloc] (unread badge refresh). Signed-in UI of the client role: orders, notifications, chat and profile
/// kept alive under a floating bottom tab bar; the "Buyurtma" slot opens the new-order wizard instead of a section.
class ClientShell extends StatelessWidget {
  /// Builds the client shell.
  const ClientShell({super.key});

  /// Index of the "new order" slot of the tab bar (it has no section of its own).
  static const _createSlot = 3;

  @override
  Widget build(BuildContext context) {
    final chatUnread = RepositoryProvider.of<ChatRepository>(context).unread;
    final inboxUnread = RepositoryProvider.of<NotificationsRepository>(context).unread;
    return IncomingCallListener(
      child: BlocProvider(
        create: (ctx) =>
            MainBloc(repository: RepositoryProvider.of<NotificationsRepository>(ctx))..add(const MainStarted()),
        child: ValueListenableBuilder<int>(
          valueListenable: homeTab,
          builder: (context, selected, _) {
            const sections = <Widget>[
              TasksScreen(),
              NotificationsScreen(tab: true),
              ChatsScreen(),
              SizedBox.shrink(),
              ClientProfileScreen(),
            ];
            final index = selected == _createSlot ? 0 : selected.clamp(0, sections.length - 1);
            return Scaffold(
              backgroundColor: theme.background,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(index: index, children: sections),
                  ),
                  FloatingTabBar(
                    selected: index,
                    onSelected: (i) => i == _createSlot ? context.push(Routes.taskNew.path) : homeTab.value = i,
                    items: [
                      TabBarItem(icon: AppIcons.tasks, label: TrWords.clOrders.tr()),
                      TabBarItem(icon: AppIcons.bell, label: TrWords.clTabNotifs.tr(), badge: inboxUnread),
                      TabBarItem(icon: AppIcons.msg, label: TrWords.navChat.tr(), badge: chatUnread),
                      TabBarItem(icon: AppIcons.plus, label: TrWords.clTabCreate.tr(), cta: true),
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
