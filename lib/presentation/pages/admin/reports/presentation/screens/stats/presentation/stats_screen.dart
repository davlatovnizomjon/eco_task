import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/stats_kind.dart';
import 'package:eco_task/domain/common/enums/stats_period.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/segment_bar.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';

import '../bloc/bloc.dart';
import 'widgets/stats_sections.dart';

/// One statistics screen of the admin report tab (finance, tasks, own, clients, staff or managers): a week / month /
/// year switch, arrows between windows, the cards of the kind and a download action. Provides [StatsBloc].
class StatsScreen extends StatelessWidget {
  /// Which of the six screens to show.
  final StatsKind kind;

  /// Builds the screen for [kind].
  const StatsScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          StatsBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx), kind: kind)..add(const StatsStarted()),
      child: _StatsView(kind: kind),
    );
  }
}

/// Renders the switch, the window arrows and the body for the current state.
class _StatsView extends StatelessWidget {
  /// Kind of the screen, for titles, icons and the body.
  final StatsKind kind;

  /// Builds the view.
  const _StatsView({required this.kind});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StatsBloc, StatsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        /// Bloc of this screen.
        final bloc = context.read<StatsBloc>();

        /// Numbers of the window; null while loading or after a failed first load.
        final report = state.report;

        /// True when the window has nothing to show: the empty state replaces the cards.
        final empty = report != null && report.isEmpty;
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: kind.title,
                actions: [
                  state.exporting
                      ? SizedBox(
                          width: 44.w,
                          height: 44.w,
                          child: Center(
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2.w, color: theme.primary),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: report == null || empty ? null : () => bloc.add(const StatsExported()),
                          icon: AppIcon(
                            AppIcons.upload,
                            color: report == null || empty ? theme.grayText.withValues(alpha: 0.45) : theme.primary,
                          ),
                        ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                child: Column(
                  children: [
                    SegmentBar(
                      labels: [for (final p in StatsPeriod.values) p.title],
                      selected: state.period.index,
                      onChanged: (i) => bloc.add(StatsPeriodChanged(StatsPeriod.values[i])),
                    ),
                    6.h.height,
                    Row(
                      children: [
                        _arrow(AppIcons.left, enabled: true, onTap: () => bloc.add(const StatsShifted(-1))),
                        Expanded(
                          child: Text(
                            StatsSections.periodTitle(state.period, state.offset),
                            textAlign: TextAlign.center,
                            style: theme.textStyle.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _arrow(AppIcons.right, enabled: state.offset < 0, onTap: () => bloc.add(const StatsShifted(1))),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: report == null
                    ? (state.status == ScreenStatus.error
                          ? EmptyView.tile(
                              icon: AppIcons.wifioff,
                              tone: StatusTone.warn,
                              title: TrWords.sxErrT.tr(),
                              message: TrWords.sxErrD.tr(),
                              onRetry: () => bloc.add(const StatsStarted()),
                            )
                          : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3)))
                    : empty
                    ? EmptyView.tile(icon: kind.icon, title: kind.emptyTitle, message: kind.emptyHint)
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h + MediaQuery.of(context).padding.bottom),
                        gap: 12,
                        onRefresh: () async {
                          bloc.add(const StatsRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        children: StatsSections.build(kind, report, state.period, state.offset),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Small chevron button that moves the window; dimmed and inert when [enabled] is false.
  Widget _arrow(String icon, {required bool enabled, required VoidCallback onTap}) => GestureDetector(
    onTap: enabled ? onTap : null,
    behavior: HitTestBehavior.opaque,
    child: Opacity(
      opacity: enabled ? 1 : 0.4,
      child: SizedBox(
        width: 32.w,
        height: 32.w,
        child: Center(
          child: AppIcon(icon, size: 20.sp, color: enabled ? theme.textSecondary : theme.grayText),
        ),
      ),
    ),
  );
}
