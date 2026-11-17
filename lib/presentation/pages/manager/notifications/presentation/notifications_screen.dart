import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/notification_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/notification_card.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';
import 'dialogs/notification_sheet.dart';

/// Pushed notifications inbox of the manager (opened from the dashboard bell): group chips, day-grouped rows with an
/// unread dot and a "mark all read" action. Provides [NotificationsBloc].
class NotificationsScreen extends StatelessWidget {
  /// Builds the screen.
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          NotificationsBloc(repository: RepositoryProvider.of<NotificationsRepository>(ctx))
            ..add(const NotificationsStarted()),
      child: const _NotificationsView(),
    );
  }
}

/// Renders the bar, the chips and the day groups.
class _NotificationsView extends StatelessWidget {
  /// Builds the view.
  const _NotificationsView();

  /// Opens the screen a notification of [kind] is about.
  void _open(BuildContext context, NotificationKind kind) {
    switch (kind) {
      case NotificationKind.review:
        // Results awaiting a decision are found in the tasks tab.
        homeTab.value = 1;
        context.go(Routes.home.path);
      case NotificationKind.expense:
        // Expenses are reviewed inside the task they belong to; the tasks tab lists what awaits a decision.
        homeTab.value = 1;
        context.go(Routes.home.path);
      case NotificationKind.request:
        context.push(Routes.clients.path);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<NotificationsBloc>();
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: TrWords.ntfTitle.tr(),
                actions: [
                  IconButton(
                    tooltip: TrWords.ntfMarkAll.tr(),
                    onPressed: state.items.any((n) => !n.isRead)
                        ? () => bloc.add(const NotificationsMarkedRead())
                        : null,
                    icon: AppIcon(
                      AppIcons.checks,
                      size: 24.sp,
                      color: state.items.any((n) => !n.isRead) ? theme.primary : theme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
              UnderlineTabs(
                labels: [TrWords.cAll.tr(), TrWords.ntfUnreadLabel.tr()],
                selected: state.group == NotificationGroup.unread ? 1 : 0,
                onChanged: (i) =>
                    bloc.add(NotificationsGroupChanged(i == 1 ? NotificationGroup.unread : NotificationGroup.all)),
              ),
              Expanded(
                child: state.items.isEmpty && state.status.isLoading
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 4))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
                        gap: 8,
                        onRefresh: () async {
                          bloc.add(const NotificationsRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        onLoadMore: () => bloc.add(const NotificationsMoreRequested()),
                        isLoadingMore: state.isLoadingMore,
                        placeholder: state.status.isError
                            ? EmptyView.tile(
                                icon: AppIcons.wifioff,
                                tone: StatusTone.error,
                                title: TrWords.ntfErrT.tr(),
                                message: TrWords.ntfErrD.tr(),
                                onRetry: () => bloc.add(const NotificationsStarted()),
                              )
                            : (state.group == NotificationGroup.unread
                                  ? EmptyView.tile(
                                      icon: AppIcons.checkc,
                                      title: TrWords.ntfEmptyUnreadT.tr(),
                                      message: TrWords.ntfEmptyUnreadD.tr(),
                                    )
                                  : EmptyView.tile(
                                      icon: AppIcons.bell,
                                      title: TrWords.ntfEmpty.tr(),
                                      message: TrWords.ntfEmptyDesc.tr(),
                                    )),
                        children: [
                          for (final n in state.items)
                            NotificationCard(
                              title: n.kind.title(n.titleArgs),
                              time: DateFormatter.ago(n.at),
                              message: n.kind.body(n.bodyArgs),
                              unread: !n.isRead,
                              onTap: () {
                                bloc.add(NotificationsMarkedRead(id: n.id));
                                NotificationSheet.show(
                                  context,
                                  title: n.kind.title(n.titleArgs),
                                  time: DateFormatter.ago(n.at),
                                  message: n.kind.body(n.bodyArgs),
                                  onOpen: () => _open(context, n.kind),
                                );
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
