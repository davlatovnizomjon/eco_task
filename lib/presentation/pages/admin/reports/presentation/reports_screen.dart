import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Reports tab (boss): task counts by status, completed tasks per week and the
/// money totals of the selected period. Provides [ReportsBloc] over the
/// app-wide [ReportsRepository].
class ReportsScreen extends StatelessWidget {
  /// True when the screen was pushed (with a back button) rather than shown as a tab.
  final bool pushed;

  /// Builds the reports screen.
  const ReportsScreen({super.key, this.pushed = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ReportsBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx))..add(const ReportsStarted()),
      child: _ReportsView(pushed: pushed),
    );
  }
}

/// Renders the period switch and the report blocks.
class _ReportsView extends StatelessWidget {
  /// True when the screen was pushed rather than shown as a tab.
  final bool pushed;

  /// Builds the reports body.
  const _ReportsView({required this.pushed});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportsBloc, ReportsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ReportsBloc>();
        final summary = state.summary;
        // Rows of the status card: status, glyph color.
        final rows = [
          (TaskStatus.done, theme.primary),
          (TaskStatus.prog, theme.info),
          (TaskStatus.rev, theme.review),
          (TaskStatus.fail, theme.red),
        ];
        // Tallest weekly value, so bars scale to the chart height.
        final peak = summary == null || summary.weekly.isEmpty
            ? 1
            : summary.weekly.reduce((a, b) => a > b ? a : b).clamp(1, 999);
        return ScreenShell(
          title: TrWords.repTitle.tr(),
          big: !pushed,
          showBack: pushed,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                child: SegmentedTabs(
                  labels: [for (final p in ReportPeriod.values) p.title],
                  selected: state.period.index,
                  onChanged: (i) => bloc.add(ReportsPeriodChanged(ReportPeriod.values[i])),
                ),
              ),
              Expanded(
                child: summary == null
                    ? (state.status.isError
                          ? EmptyView(
                              title: TrWords.cLoadFailed.tr(),
                              message: TrWords.cLoadFailedDesc.tr(),
                              icon: AppIcons.alert,
                              onRetry: () => bloc.add(const ReportsStarted()),
                            )
                          : const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading(count: 3)))
                    : RefreshList(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        gap: 16,
                        onRefresh: () async {
                          bloc.add(const ReportsRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        children: [
                          CardWidget(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(TrWords.repByStatus.tr(), style: theme.cardTitle)),
                                    Text(TrWords.cTasksN.tr(args: ['${summary.total}']), style: theme.cardSubtitle),
                                  ],
                                ),
                                8.h.height,
                                for (final (status, color) in rows)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6.h),
                                    child: Row(
                                      children: [
                                        AppIcon(status.icon, color: color),
                                        10.w.width,
                                        Expanded(child: Text(status.title, style: theme.textStyle)),
                                        Text('${summary.countOf(status)}', style: theme.cardTitle),
                                      ],
                                    ),
                                  ),
                                6.h.height,
                                Text(
                                  TrWords.repLateNote.tr(args: ['${summary.lateDelivered + summary.overdue}']),
                                  style: theme.cardSubtitle,
                                ),
                              ],
                            ),
                          ),
                          CardWidget(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(TrWords.repWeekly.tr(), style: theme.cardTitle),
                                16.h.height,
                                SizedBox(
                                  height: 120.h,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      for (final (i, value) in summary.weekly.indexed)
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                '$value',
                                                style: theme.badgeText.copyWith(color: theme.textSecondary),
                                              ),
                                              4.h.height,
                                              Container(
                                                height: 90.h * value / peak,
                                                margin: EdgeInsets.symmetric(horizontal: 14.w),
                                                decoration: BoxDecoration(
                                                  color: i == summary.weekly.length - 1
                                                      ? theme.primary
                                                      : theme.primaryTint,
                                                  borderRadius: 6.circular,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CardWidget(
                            child: Column(
                              children: [
                                InfoRow(label: TrWords.repRewards.tr(), value: MoneyFormatter.display(summary.rewards)),
                                InfoRow(label: TrWords.repExp.tr(), value: MoneyFormatter.display(summary.expenses)),
                                InfoRow(label: TrWords.repPaid.tr(), value: MoneyFormatter.display(summary.paid)),
                              ],
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
