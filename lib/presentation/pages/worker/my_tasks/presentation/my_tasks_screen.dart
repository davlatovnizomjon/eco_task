import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/task_card.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// The worker's tasks: an "active" tab of cards and a "history" tab of closed
/// tasks with monthly reward totals. [historyOnly] opens the pushed history
/// screen from the profile. Provides [MyTasksBloc] over [TasksRepository].
class MyTasksScreen extends StatelessWidget {
  /// True when opened from the profile: starts on history and shows a back button.
  final bool historyOnly;

  /// Builds the screen.
  const MyTasksScreen({super.key, this.historyOnly = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          MyTasksBloc(repository: RepositoryProvider.of<TasksRepository>(ctx), historyFirst: historyOnly)
            ..add(const MyTasksStarted()),
      child: _MyTasksView(historyOnly: historyOnly),
    );
  }
}

/// Renders the tab switch and the list of the selected tab.
class _MyTasksView extends StatelessWidget {
  /// True when the screen was pushed rather than shown as a tab.
  final bool historyOnly;

  /// Builds the list body.
  const _MyTasksView({required this.historyOnly});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyTasksBloc, MyTasksState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<MyTasksBloc>();
        final history = state.tab == 1;
        final done = state.items.where((t) => t.status == TaskStatus.done);
        return ScreenShell(
          title: TrWords.navMyTasks.tr(),
          big: !historyOnly,
          showBack: historyOnly,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                child: SegmentedTabs(
                  labels: [TrWords.wTabActive.tr(), TrWords.wTabHistory.tr()],
                  selected: state.tab,
                  onChanged: (i) => bloc.add(MyTasksTabChanged(i)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: state.items.isEmpty && state.status.isLoading
                      ? const SmartLoading(count: 3)
                      : RefreshList(
                          onRefresh: () async {
                            bloc.add(const MyTasksRefreshed());
                            await bloc.stream.firstWhere((s) => !s.refreshing);
                          },
                          onLoadMore: () => bloc.add(const MyTasksMoreRequested()),
                          isLoadingMore: state.isLoadingMore,
                          placeholder: state.status.isError
                              ? EmptyView(
                                  title: TrWords.cLoadFailed.tr(),
                                  message: TrWords.cLoadFailedDesc.tr(),
                                  icon: AppIcons.alert,
                                  onRetry: () => bloc.add(const MyTasksStarted()),
                                )
                              : EmptyView(
                                  title: TrWords.wEmptyToday.tr(),
                                  message: TrWords.wEmptyTodayDesc.tr(),
                                  icon: AppIcons.check,
                                ),
                          children: [
                            if (!history)
                              for (final task in state.items)
                                TaskCard(task: task, onTap: () => context.push(Routes.taskDetail.of(task.id)))
                            else ...[
                              CardWidget(
                                child: Column(
                                  children: [
                                    InfoRow(
                                      label: TrWords.wMonthReward.tr(),
                                      value: MoneyFormatter.display(done.fold(0, (s, t) => s + t.reward)),
                                    ),
                                    InfoRow(
                                      label: TrWords.teamPaid.tr(),
                                      value: MoneyFormatter.display(
                                        done.where((t) => t.isPaid).fold(0, (s, t) => s + t.reward),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CardWidget(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    for (final (i, task) in state.items.indexed)
                                      OptionTile(
                                        title: task.title,
                                        first: i == 0,
                                        subtitle:
                                            '${DateFormatter.day(task.due)}${task.reward > 0 ? ' · ${MoneyFormatter.display(task.reward)}' : ''}${task.status == TaskStatus.done ? ' · ${(task.isPaid ? TrWords.esPaid : TrWords.esPend).tr()}' : ''}',
                                        trailing: StatusChip.task(task.status),
                                        onTap: () => context.push(Routes.taskDetail.of(task.id)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
