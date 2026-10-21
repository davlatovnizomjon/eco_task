import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/task_card.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Worker home tab: the next step as a hero card, then today's and tomorrow's
/// tasks. Provides [TodayBloc] over the app-wide [TasksRepository].
class TodayScreen extends StatelessWidget {
  /// Builds the worker home.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TodayBloc(repository: RepositoryProvider.of<TasksRepository>(ctx))..add(const TodayStarted()),
      child: const _TodayView(),
    );
  }
}

/// Renders the greeting header, the hero card and the day groups.
class _TodayView extends StatelessWidget {
  /// Builds the home body.
  const _TodayView();

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    return BlocConsumer<TodayBloc, TodayState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<TodayBloc>();
        // The task with a quota is the hero when there is one; else the soonest.
        final TaskModel? next =
            state.items.where((t) => t.status.isOpen && t.assigneeOf(me.id)?.share != 0).firstOrNull ??
            state.items.where((t) => t.status.isOpen).firstOrNull;
        final rest = state.items.where((t) => t != next && t.status.isOpen).toList();
        final today = rest.where((t) => DateFormatter.daysTo(t.due) <= 0).toList();
        final tomorrow = rest.where((t) => DateFormatter.daysTo(t.due) == 1).toList();
        final mine = next?.assigneeOf(me.id);
        return ScreenShell(
          title: TrWords.wHello.tr(args: [me.firstName]),
          subtitle: DateFormatter.weekdayDay(DateTime.now()),
          big: true,
          showBack: false,
          padding: EdgeInsets.zero,
          actions: [
            Padding(
              padding: 8.w.right,
              child: UserAvatar(me.ref, size: 36.w),
            ),
          ],
          child: state.items.isEmpty && state.status.isLoading
              ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SmartLoading())
              : RefreshList(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  gap: 20,
                  onRefresh: () async {
                    bloc.add(const TodayRefreshed());
                    await bloc.stream.firstWhere((s) => !s.refreshing);
                  },
                  placeholder: state.status.isError
                      ? EmptyView(
                          title: TrWords.cLoadFailed.tr(),
                          message: TrWords.cLoadFailedDesc.tr(),
                          icon: AppIcons.alert,
                          onRetry: () => bloc.add(const TodayStarted()),
                        )
                      : EmptyView(
                          title: TrWords.wEmptyToday.tr(),
                          message: TrWords.wEmptyTodayDesc.tr(),
                          icon: AppIcons.check,
                        ),
                  children: [
                    if (next != null)
                      CardWidget(
                        color: theme.primaryTint,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    TrWords.wNext.tr(),
                                    style: theme.fieldLabel.copyWith(color: theme.primaryDark),
                                  ),
                                ),
                                Text(next.id, style: theme.fieldLabel.copyWith(color: theme.textSecondary)),
                              ],
                            ),
                            8.h.height,
                            Text(
                              next.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.cardTitle.copyWith(fontSize: 18.sp),
                            ),
                            if (mine != null && mine.share > 0) ...[
                              12.h.height,
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: 3.circular,
                                      child: LinearProgressIndicator(
                                        value: (mine.done / mine.share).clamp(0, 1).toDouble(),
                                        minHeight: 6.h,
                                        backgroundColor: theme.cardColor,
                                        color: theme.primary,
                                      ),
                                    ),
                                  ),
                                  10.w.width,
                                  Text(
                                    '${TrWords.tasksMyShare.tr()}: ${mine.done} / ${mine.share}',
                                    style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                            12.h.height,
                            Row(
                              children: [
                                AppIcon(AppIcons.cal, size: 16.sp, color: theme.textSecondary),
                                4.w.width,
                                Expanded(
                                  child: Text(
                                    DateFormatter.due(next.due),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                                  ),
                                ),
                                StatusChip.task(next.status),
                              ],
                            ),
                            14.h.height,
                            Row(
                              children: [
                                Expanded(
                                  child: Btn.unActive(
                                    text: TrWords.cUpdate.tr(),
                                    icon: AppIcons.edit,
                                    height: 40.h,
                                    onPressed: () => context.push(Routes.taskDetail.of(next.id)),
                                  ),
                                ),
                                8.w.width,
                                Expanded(
                                  child: Btn(
                                    text: TrWords.cOpen.tr(),
                                    icon: AppIcons.right,
                                    height: 40.h,
                                    onPressed: () => context.push(Routes.taskDetail.of(next.id)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // The two day groups share one layout: a label over a stack of cards.
                    for (final (label, tasks) in [
                      (TrWords.wTodayN.tr(args: ['${today.length}']), today),
                      (TrWords.cTomorrow.tr(), tomorrow),
                    ])
                      if (tasks.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: theme.sectionLabel),
                            8.h.height,
                            for (final task in tasks)
                              Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: TaskCard(task: task, onTap: () => context.push(Routes.taskDetail.of(task.id))),
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
