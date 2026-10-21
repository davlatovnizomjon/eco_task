import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Task counts by status for a period, plus the overdue counter. Provides
/// [TaskStatusBloc] over the app-wide [ReportsRepository].
class TaskStatusScreen extends StatelessWidget {
  /// Builds the screen.
  const TaskStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          TaskStatusBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx))..add(const TaskStatusStarted()),
      child: const _TaskStatusView(),
    );
  }
}

/// Renders the period switch, the big total and the per-status rows.
class _TaskStatusView extends StatelessWidget {
  /// Builds the screen body.
  const _TaskStatusView();

  @override
  Widget build(BuildContext context) {
    final team = RepositoryProvider.of<SessionRepository>(context).user.value!.user.team;
    return BlocConsumer<TaskStatusBloc, TaskStatusState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TaskStatusBloc>();
        final summary = state.summary;
        return ScreenShell(
          title: TrWords.tasksByStatus.tr(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                child: SegmentedTabs(
                  labels: [for (final p in ReportPeriod.values) p.title],
                  selected: state.period.index,
                  onChanged: (i) => bloc.add(TaskStatusPeriodChanged(ReportPeriod.values[i])),
                ),
              ),
              Expanded(
                child: summary == null
                    ? (state.status.isError
                          ? EmptyView(
                              title: TrWords.cLoadFailed.tr(),
                              message: TrWords.cLoadFailedDesc.tr(),
                              icon: AppIcons.alert,
                              onRetry: () => bloc.add(const TaskStatusStarted()),
                            )
                          : const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading(count: 2)))
                    : RefreshList(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        gap: 14,
                        onRefresh: () async {
                          bloc.add(const TaskStatusRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        children: [
                          CardWidget(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${summary.total}', style: theme.screenTitle.copyWith(fontSize: 40.sp, height: 1)),
                                8.w.width,
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 4.h),
                                    child: Text(
                                      TrWords.tasksTasksCount.tr(args: [team.isEmpty ? 'Eco' : team]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.cardSubtitle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CardWidget(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (final (i, status) in TaskStatus.values.indexed)
                                  OptionTile(
                                    title: '',
                                    first: i == 0,
                                    leading: StatusChip.task(status),
                                    onTap: () => homeTab.value = 1,
                                    trailing: Text('${summary.countOf(status)}', style: theme.cardTitle),
                                  ),
                              ],
                            ),
                          ),
                          CardWidget(
                            padding: EdgeInsets.zero,
                            child: OptionTile(
                              title: TrWords.tasksOverAny.tr(),
                              subtitle: TrWords.tasksRegardless.tr(),
                              first: true,
                              leading: AppIcon.tile(AppIcons.alarm, tone: StatusTone.warn),
                              onTap: () => homeTab.value = 1,
                              trailing: Text('${summary.overdue}', style: theme.cardTitle.copyWith(color: theme.warn)),
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
}
