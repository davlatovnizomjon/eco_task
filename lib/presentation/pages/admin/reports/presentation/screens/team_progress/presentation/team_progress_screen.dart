import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Per-person results of the manager's team for a period. Provides
/// [TeamProgressBloc] over the app-wide [ReportsRepository].
class TeamProgressScreen extends StatelessWidget {
  /// Builds the screen.
  const TeamProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          TeamProgressBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx))..add(const TeamProgressStarted()),
      child: const _TeamProgressView(),
    );
  }
}

/// Renders the period switch and one card per worker.
class _TeamProgressView extends StatelessWidget {
  /// Builds the screen body.
  const _TeamProgressView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamProgressBloc, TeamProgressState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TeamProgressBloc>();
        final summary = state.summary;
        return ScreenShell(
          title: TrWords.repTeamResult.tr(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 6.h),
                child: SegmentedTabs(
                  labels: [ReportPeriod.week.title, ReportPeriod.month.title],
                  selected: state.period.index.clamp(0, 1),
                  onChanged: (i) => bloc.add(TeamProgressPeriodChanged(ReportPeriod.values[i])),
                ),
              ),
              Expanded(
                child: summary == null
                    ? (state.status.isError
                          ? EmptyView(
                              title: TrWords.cLoadFailed.tr(),
                              message: TrWords.cLoadFailedDesc.tr(),
                              icon: AppIcons.alert,
                              onRetry: () => bloc.add(const TeamProgressStarted()),
                            )
                          : const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading(count: 3)))
                    : RefreshList(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        gap: 12,
                        onRefresh: () async {
                          bloc.add(const TeamProgressRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        placeholder: EmptyView(title: TrWords.cEmptyTitle.tr(), icon: AppIcons.users),
                        children: [
                          for (final stat in summary.people)
                            CardWidget(
                              child: Row(
                                children: [
                                  UserAvatar(stat.user.ref, size: 40.w),
                                  12.w.width,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          stat.user.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.cardTitle,
                                        ),
                                        Text(
                                          stat.hasLate
                                              ? TrWords.repLateTask.tr(args: ['${stat.lateDays}'])
                                              : TrWords.repOnTimeOf.tr(args: ['${stat.onTime}', '${stat.done}']),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.cardSubtitle.copyWith(color: stat.hasLate ? theme.warn : null),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${stat.done} / ${stat.total}', style: theme.cardTitle),
                                ],
                              ),
                            ),
                          Text(TrWords.repOnlyTeam.tr(), style: theme.cardSubtitle),
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
