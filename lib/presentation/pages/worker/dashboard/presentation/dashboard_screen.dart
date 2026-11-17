import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/dashboard_summary.dart';
import 'package:eco_task/infrastructure/repository/notifications_repository.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/header_action.dart';
import 'package:eco_task/presentation/public/widgets/large_title_header.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/section_head.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';

import '../bloc/bloc.dart';
import 'widgets/dashboard_hint_card.dart';
import 'widgets/my_tasks_stack.dart';
import 'widgets/today_tasks_card.dart';
import 'widgets/weekly_card.dart';

/// Worker home tab: greeting header, the worker's own tasks, weekly progress and today's deadlines. Provides [DashboardBloc].
class DashboardScreen extends StatelessWidget {
  /// Builds the dashboard.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    return BlocProvider(
      create: (ctx) => DashboardBloc(
        repository: RepositoryProvider.of<ReportsRepository>(ctx),
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        meId: me.id,
      )..add(const DashboardStarted()),
      child: const _DashboardView(),
    );
  }
}

/// Renders the header and the summary sections.
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
        return Column(
          children: [
            LargeTitleHeader(
              title: me.name,
              custom: Row(
                children: [
                  GestureDetector(
                    // The avatar opens the profile tab.
                    onTap: () => homeTab.value = 4,
                    child: UserAvatar(me.ref, size: 44.w),
                  ),
                  12.w.width,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((state.isBlank ? TrWords.dashWelcome : TrWords.dashGreet).tr(), style: theme.cardSubtitle),
                        Text(
                          me.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(
                            fontSize: 18.sp,
                            height: 22 / 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: unread,
                    builder: (context, count, _) => HeaderAction(
                      icon: AppIcons.bell,
                      badge: count,
                      onTap: () => context.push(Routes.notifications.path),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: summary == null
                  ? (state.status.isError
                        ? EmptyView(
                            title: TrWords.cLoadFailed.tr(),
                            message: TrWords.cLoadFailedDesc.tr(),
                            icon: AppIcons.alert,
                            onRetry: () => bloc.add(const DashboardStarted()),
                          )
                        : const Padding(padding: EdgeInsets.all(16), child: SmartLoading()))
                  : RefreshList(
                      padding: EdgeInsets.fromLTRB(16.w, state.isBlank ? 24.h : 14.h, 16.w, 120.h),
                      gap: state.isBlank ? 12 : 11,
                      onRefresh: () async {
                        bloc.add(const DashboardRefreshed());
                        await bloc.stream.firstWhere((s) => !s.refreshing);
                      },
                      children: state.isBlank ? _welcome(context) : _blocks(context, state, summary),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Sections of a working day: own tasks, the week, today's deadlines. A block without data is replaced by its hint
  /// card (a worker cannot add tasks, so the hints have no "add" button).
  List<Widget> _blocks(BuildContext context, DashboardState state, DashboardSummary summary) {
    return [
      if (state.mine.isNotEmpty)
        MyTasksStack(tasks: state.mine)
      else ...[
        SectionHead(TrWords.dashMyTasks.tr()),
        DashboardHintCard(icon: AppIcons.checkc, title: TrWords.dashNoMineT.tr(), subtitle: TrWords.wkNoMineD.tr()),
      ],
      if (state.week != null) WeeklyCard(report: state.week!),
      SectionHead(
        TrWords.dashTodayTasks.tr(),
        action: summary.dueToday.isEmpty ? null : TrWords.cAll.tr(),
        chevron: true,
        onAction: () => context.push(Routes.todayTasks.path),
      ),
      if (summary.dueToday.isNotEmpty)
        TodayTasksCard(tasks: summary.dueToday)
      else
        DashboardHintCard(icon: AppIcons.cal, title: TrWords.dashNoTodayT.tr(), subtitle: TrWords.wkNoTodayD.tr()),
    ];
  }

  /// First-run content of a worker with no tasks: a greeting block.
  List<Widget> _welcome(BuildContext context) => [
    Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 14.h),
      child: Column(
        children: [
          AppIcon.tile(AppIcons.tasks, tone: StatusTone.primary, size: 64),
          14.h.height,
          Text(
            TrWords.wkBlankT.tr(),
            textAlign: TextAlign.center,
            style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
          ),
          6.h.height,
          Text(
            TrWords.wkBlankD.tr(),
            textAlign: TextAlign.center,
            style: theme.cardSubtitle.copyWith(fontSize: 15.sp, height: 21 / 15),
          ),
        ],
      ),
    ),
  ];
}
