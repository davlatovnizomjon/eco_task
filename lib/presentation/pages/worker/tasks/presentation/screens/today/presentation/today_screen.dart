import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/task_line.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

/// Pushed list of today's tasks (due today or overdue) opened from the dashboard. Provides [TodayBloc].
class TodayScreen extends StatelessWidget {
  /// Builds the screen.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TodayBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx))..add(const TodayStarted()),
      child: const _TodayView(),
    );
  }
}

/// Renders the bar, the chips and the rows.
class _TodayView extends StatelessWidget {
  /// Builds the view.
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TodayBloc, TodayState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TodayBloc>();
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(title: TrWords.dashTodayTasks.tr()),
              Expanded(
                child: state.status.isLoading
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading())
                    : state.status.isError
                    ? EmptyView(
                        title: TrWords.cLoadFailed.tr(),
                        message: TrWords.cLoadFailedDesc.tr(),
                        icon: AppIcons.alert,
                        onRetry: () => bloc.add(const TodayStarted()),
                      )
                    : Column(
                        children: [
                          UnderlineTabs(
                            labels: [
                              TrWords.cAll.tr(),
                              TrWords.stProg.tr(),
                              TrWords.stNew.tr(),
                              TrWords.dashOverdue.tr(),
                            ],
                            selected: state.filter,
                            onChanged: (i) => bloc.add(TodayFilterChanged(i)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateFormatter.weekdayDay(DateTime.now()),
                                          style: theme.cardSubtitle,
                                        ),
                                      ),
                                      Text(
                                        TrWords.todayDoneOf.tr(args: ['${state.doneCount}', '${state.tasks.length}']),
                                        style: theme.cardSubtitle,
                                      ),
                                    ],
                                  ),
                                  6.h.height,
                                  Expanded(
                                    child: RefreshList(
                                      padding: EdgeInsets.only(bottom: ScreenSize.bottomInset(context) + 8.h),
                                      gap: 0,
                                      onRefresh: () async {
                                        bloc.add(const TodayRefreshed());
                                        await bloc.stream.firstWhere((s) => !s.refreshing);
                                      },
                                      placeholder: EmptyView(
                                        title: TrWords.tasksEmpty.tr(),
                                        message: TrWords.tasksEmptyDesc.tr(),
                                        icon: AppIcons.search,
                                      ),
                                      children: [
                                        for (final (i, task) in state.visible.indexed)
                                          TaskLine(
                                            first: i == 0,
                                            inset: 2,
                                            time: task.isOverdue
                                                ? TrWords.cEmptyValue.tr()
                                                : DateFormatter.time(task.due),
                                            dot: task.isOverdue
                                                ? theme.red
                                                : (task.status == TaskStatus.done
                                                      ? theme.primary
                                                      : (task.status == TaskStatus.prog ? theme.info : theme.neutral)),
                                            title: task.title,
                                            subtitle: _subtitle(task),
                                            trailing: task.isOverdue
                                                ? StatusChip.overdueCompact()
                                                : StatusChip.taskCompact(task.status, icon: false),
                                            onTap: () => context.push(Routes.taskDetail.of(task.id)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  /// Assignee names, plus the lateness note for overdue tasks.
  String _subtitle(TaskModel task) {
    final names = task.assignees.map((a) => a.user.firstName).join(', ');
    if (task.isOverdue) return '$names · ${TrWords.cDaysLate.tr(args: ['${task.lateDays}'])}';
    return names;
  }
}
