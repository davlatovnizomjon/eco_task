import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/expense_status.dart';
import 'package:eco_task/domain/common/enums/log_kind.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Profile of one staff member (boss view): counters, money and the task lists.
/// Provides [EmployeeBloc] over the app-wide team and task repositories.
class EmployeeScreen extends StatelessWidget {
  /// Id of the employee to show.
  final String userId;

  /// Builds the profile screen.
  const EmployeeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => EmployeeBloc(
        team: RepositoryProvider.of<TeamRepository>(ctx),
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        userId: userId,
      )..add(const EmployeeStarted()),
      child: const _EmployeeView(),
    );
  }
}

/// Renders the header, counters, money block and task tabs.
class _EmployeeView extends StatelessWidget {
  /// Builds the profile body.
  const _EmployeeView();

  @override
  Widget build(BuildContext context) {
    final admin = RepositoryProvider.of<SessionRepository>(context).role == UserRole.owner;
    return BlocConsumer<EmployeeBloc, EmployeeState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<EmployeeBloc>();
        final user = state.user;
        if (user == null) {
          return ScreenShell(
            title: TrWords.teamTitle.tr(),
            child: state.status.isError
                ? EmptyView(
                    title: TrWords.cLoadFailed.tr(),
                    message: TrWords.cLoadFailedDesc.tr(),
                    icon: AppIcons.alert,
                    onRetry: () => bloc.add(const EmployeeStarted()),
                  )
                : const SmartLoading(count: 2),
          );
        }
        final active = state.items.where((t) => !t.status.isClosed).toList();
        final past = state.items.where((t) => t.status.isClosed).toList();
        final done = state.items.where((t) => t.status == TaskStatus.done).toList();
        // Tasks completed no later than their deadline.
        final onTime = done
            .where((t) => !(t.log.where((l) => l.kind == LogKind.done).firstOrNull?.at ?? t.due).isAfter(t.due))
            .length;
        final expenses = [for (final t in state.items) ...t.expenses.where((e) => e.user.id == user.id)];
        final list = state.tab == 0 ? active : past;
        return ScreenShell(
          title: user.name,
          padding: EdgeInsets.zero,
          actions: [
            if (admin)
              IconButton(
                onPressed: () => context.push(Routes.roles.of(user.id)),
                icon: AppIcon(AppIcons.shield, color: theme.text),
              ),
          ],
          child: RefreshList(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            gap: 16,
            onRefresh: () async {
              bloc.add(const EmployeeRefreshed());
              await bloc.stream.firstWhere((s) => !s.refreshing);
            },
            children: [
              Row(
                children: [
                  UserAvatar(user.ref, size: 56.w),
                  14.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.screenTitle.copyWith(fontSize: 22.sp),
                        ),
                        Text(
                          '${user.role.title} · ${user.team}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.cardSubtitle,
                        ),
                        if (user.phone.isNotEmpty) Text(PhoneFormatter.display(user.phone), style: theme.cardSubtitle),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final (i, (value, label)) in [
                    ('${active.length}', TrWords.teamActive),
                    ('${done.length}', TrWords.teamDoneMonth),
                    ('$onTime / ${done.length}', TrWords.teamOnTime),
                  ].indexed) ...[
                    if (i > 0) 8.w.width,
                    Expanded(
                      child: CardWidget(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(value, style: theme.screenTitle.copyWith(fontSize: 22.sp)),
                            Text(
                              label.tr(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              CardWidget(
                child: Column(
                  children: [
                    InfoRow(
                      label: TrWords.teamRewardOk.tr(),
                      value: MoneyFormatter.display(done.fold(0, (s, t) => s + t.reward)),
                    ),
                    InfoRow(
                      label: TrWords.teamPaid.tr(),
                      value: MoneyFormatter.display(done.where((t) => t.isPaid).fold(0, (s, t) => s + t.reward)),
                    ),
                    InfoRow(
                      label: TrWords.teamExpOk.tr(),
                      value: MoneyFormatter.display(
                        expenses.fold(0, (s, e) => s + (e.status == ExpenseStatus.approved ? e.approvedAmount : 0)),
                      ),
                      valueColor: theme.primary,
                    ),
                    InfoRow(
                      label: TrWords.teamInReview.tr(),
                      value: MoneyFormatter.display(
                        expenses.fold(0, (s, e) => s + (e.status == ExpenseStatus.pending ? e.amount : 0)),
                      ),
                      valueColor: theme.warn,
                    ),
                  ],
                ),
              ),
              SegmentedTabs(
                labels: [
                  TrWords.teamActiveTab.tr(args: ['${active.length}']),
                  TrWords.teamHistory.tr(args: ['${past.length}']),
                ],
                selected: state.tab,
                onChanged: (i) => bloc.add(EmployeeTabChanged(i)),
              ),
              if (list.isEmpty)
                SizedBox(
                  height: 160.h,
                  child: EmptyView(title: TrWords.tasksEmpty.tr(), icon: AppIcons.board),
                )
              else
                CardWidget(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, task) in list.indexed)
                        OptionTile(
                          title: task.title,
                          first: i == 0,
                          subtitle:
                              '${task.code} · ${DateFormatter.day(task.due)}${task.reward > 0 ? ' · ${MoneyFormatter.display(task.reward)}' : ''}',
                          trailing: StatusChip.task(task.status),
                          onTap: () => context.push(Routes.taskDetail.of(task.id)),
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
