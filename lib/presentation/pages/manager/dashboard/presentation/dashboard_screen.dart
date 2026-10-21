import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/task_card.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Boss home tab: what needs attention, today's deadlines and the team's
/// progress. Provides [DashboardBloc] over the app-wide [ReportsRepository].
class DashboardScreen extends StatelessWidget {
  /// Builds the dashboard.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          DashboardBloc(repository: RepositoryProvider.of<ReportsRepository>(ctx))..add(const DashboardStarted()),
      child: const _DashboardView(),
    );
  }
}

/// Renders the greeting header and the summary sections.
class _DashboardView extends StatelessWidget {
  /// Builds the dashboard body.
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    final unread = RepositoryProvider.of<NotificationsRepository>(context).unread;
    return BlocConsumer<DashboardBloc, DashboardState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<DashboardBloc>();
        final summary = state.summary;
        return ScreenShell(
          title: TrWords.dashHello.tr(args: [me.firstName]),
          subtitle: DateFormatter.weekdayDay(DateTime.now()),
          big: true,
          showBack: false,
          padding: EdgeInsets.zero,
          actions: [
            ValueListenableBuilder<int>(
              valueListenable: unread,
              builder: (context, count, _) => GestureDetector(
                onTap: () => context.push(Routes.notifications.path),
                child: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: 12.circular,
                      border: Border.all(color: theme.line),
                    ),
                    child: AppIcon(AppIcons.bell, color: theme.text),
                  ),
                ),
              ),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(Routes.taskNew.path),
            backgroundColor: theme.primary,
            foregroundColor: theme.onPrimary,
            icon: AppIcon(AppIcons.plus, color: theme.onPrimary),
            label: Text(
              TrWords.tasksNewBtn.tr(),
              style: theme.textStyle.copyWith(fontWeight: FontWeight.w700, color: theme.onPrimary),
            ),
          ),
          child: summary == null
              ? (state.status.isError
                    ? EmptyView(
                        title: TrWords.cLoadFailed.tr(),
                        message: TrWords.cLoadFailedDesc.tr(),
                        icon: AppIcons.alert,
                        onRetry: () => bloc.add(const DashboardStarted()),
                      )
                    : const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading()))
              : RefreshList(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  gap: 20,
                  onRefresh: () async {
                    bloc.add(const DashboardRefreshed());
                    await bloc.stream.firstWhere((s) => !s.refreshing);
                  },
                  children: [
                    if (me.role == UserRole.assistant)
                      NoticeBanner(
                        text: TrWords.dashTeamBanner.tr(args: [me.team, '${summary.team.length}']),
                        tone: StatusTone.primary,
                        icon: AppIcons.users,
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(TrWords.dashAttention.tr(), style: theme.sectionLabel),
                        8.h.height,
                        Row(
                          children: [
                            for (final (i, (icon, tone, count, label, route)) in [
                              (AppIcons.eye, StatusTone.review, summary.inReview, TrWords.dashInReview, Routes.review),
                              (
                                AppIcons.alarm,
                                StatusTone.warn,
                                summary.overdue,
                                TrWords.dashOverdue,
                                Routes.taskStatus,
                              ),
                              (
                                AppIcons.receipt,
                                StatusTone.info,
                                summary.pendingExpenses,
                                TrWords.dashExpenses,
                                Routes.expenses,
                              ),
                            ].indexed) ...[
                              if (i > 0) 8.w.width,
                              Expanded(
                                child: CardWidget(
                                  onTap: () => context.push(route.path),
                                  padding: EdgeInsets.all(12.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AppIcon.tile(icon, tone: tone, size: 36),
                                      10.h.height,
                                      Text('$count', style: theme.screenTitle.copyWith(fontSize: 26.sp, height: 1)),
                                      2.h.height,
                                      Text(
                                        label.tr(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                TrWords.dashDueToday.tr(args: ['${summary.dueToday.length}']),
                                style: theme.sectionLabel,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => homeTab.value = 1,
                              child: Text(TrWords.cAll.tr(), style: theme.badgeText.copyWith(color: theme.primary)),
                            ),
                          ],
                        ),
                        8.h.height,
                        if (summary.dueToday.isEmpty)
                          CardWidget(child: Text(TrWords.cEmptyTitle.tr(), style: theme.cardSubtitle))
                        else
                          Column(
                            children: [
                              for (final task in summary.dueToday)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: TaskCard(task: task, onTap: () => context.push(Routes.taskDetail.of(task.id))),
                                ),
                            ],
                          ),
                      ],
                    ),
                    if (summary.team.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(TrWords.dashTeamWeek.tr(), style: theme.sectionLabel)),
                              GestureDetector(
                                onTap: () => me.role == UserRole.assistant
                                    ? context.push(Routes.teamProgress.path)
                                    : homeTab.value = 3,
                                child: Text(
                                  TrWords.cReport.tr(),
                                  style: theme.badgeText.copyWith(color: theme.primary),
                                ),
                              ),
                            ],
                          ),
                          8.h.height,
                          CardWidget(
                            child: Column(
                              children: [
                                for (final stat in summary.team)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6.h),
                                    child: Row(
                                      children: [
                                        UserAvatar(stat.user.ref, size: 28.w),
                                        10.w.width,
                                        SizedBox(
                                          width: 84.w,
                                          child: Text(
                                            stat.user.firstName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textStyle,
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: 3.circular,
                                            child: LinearProgressIndicator(
                                              value: stat.total == 0 ? 0 : stat.done / stat.total,
                                              minHeight: 6.h,
                                              backgroundColor: theme.cardColorLight,
                                              color: stat.hasLate ? theme.warn : theme.primary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 44.w,
                                          child: Text(
                                            '${stat.done}/${stat.total}',
                                            textAlign: TextAlign.right,
                                            style: theme.cardSubtitle,
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
                  ],
                ),
        );
      },
    );
  }
}
