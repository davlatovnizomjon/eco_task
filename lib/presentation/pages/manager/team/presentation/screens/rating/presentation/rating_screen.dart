import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/report_period.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/person_stat.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/presentation/pages/manager/reports/reports.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/underline_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// Pushed ranking of employees by completed tasks. Reuses the reports feature's [ReportsBloc] and shows the people
/// of its summary, best first.
class RatingScreen extends StatelessWidget {
  /// Builds the screen.
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          ReportsBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx))..add(const ReportsStarted()),
      child: const _RatingView(),
    );
  }
}

/// Renders the bar, the period switch and the ranked rows.
class _RatingView extends StatelessWidget {
  /// Builds the view.
  const _RatingView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportsBloc, ReportsState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ReportsBloc>();
        final people = state.summary == null
            ? <PersonStat>[]
            : ([...state.summary!.people]..sort((a, b) => b.done.compareTo(a.done)));
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(title: TrWords.ratingTitle.tr()),
              UnderlineTabs(
                labels: [TrWords.tasksThisWeek.tr(), TrWords.ratingMonth.tr(), TrWords.repQuarter.tr()],
                selected: state.period.index,
                onChanged: (i) => bloc.add(ReportsPeriodChanged(ReportPeriod.values[i])),
              ),
              Expanded(
                child: state.summary == null
                    ? (state.status.isError
                          ? EmptyView(
                              title: TrWords.cLoadFailed.tr(),
                              message: TrWords.cLoadFailedDesc.tr(),
                              icon: AppIcons.alert,
                              onRetry: () => bloc.add(const ReportsStarted()),
                            )
                          : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3)))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
                        gap: 0,
                        onRefresh: () async {
                          bloc.add(const ReportsRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        placeholder: EmptyView(title: TrWords.cEmptyTitle.tr(), icon: AppIcons.users),
                        children: [for (final (i, p) in people.indexed) _RankRow(rank: i + 1, stat: p, first: i == 0)],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One ranked row: place badge, avatar, name with done / total, and a bar with the on-time percentage.
class _RankRow extends StatelessWidget {
  /// 1-based place.
  final int rank;

  /// Statistics of the person.
  final PersonStat stat;

  /// True for the first row (no top hairline).
  final bool first;

  /// Builds the row.
  const _RankRow({required this.rank, required this.stat, required this.first});

  @override
  Widget build(BuildContext context) {
    final share = stat.total == 0 ? 0.0 : stat.done / stat.total;
    final onTime = stat.done == 0 ? 0 : (stat.onTime * 100 / stat.done).round().clamp(0, 100);
    return GestureDetector(
      onTap: () => context.push(Routes.employee.of(stat.user.id)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 11.h),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 26.w,
              height: 26.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rank == 1
                    ? theme.primary
                    : rank <= 3
                    ? theme.primaryTint
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: theme.textStyle.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: rank == 1
                      ? theme.onPrimary
                      : rank <= 3
                      ? theme.primary
                      : theme.grayText,
                ),
              ),
            ),
            12.w.width,
            UserAvatar(stat.user.ref, size: 40.w),
            12.w.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stat.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                      6.w.width,
                      Text(
                        '${stat.done}/${stat.total}',
                        style: theme.textStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  4.h.height,
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: 3.circular,
                          child: LinearProgressIndicator(
                            value: share,
                            minHeight: 6.h,
                            color: theme.primary,
                            backgroundColor: theme.cardColorLight,
                          ),
                        ),
                      ),
                      8.w.width,
                      Text('$onTime%', style: theme.cardSubtitle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
