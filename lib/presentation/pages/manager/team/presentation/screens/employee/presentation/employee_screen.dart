import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/presentation/public/dialogs/action_menu.dart';
import 'package:eco_task/presentation/public/dialogs/confirm_dialog.dart';
import 'package:eco_task/presentation/public/toast/toast_helpers.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/list_row.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/section_head.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';
import 'widgets/count_row.dart';

/// Profile of one staff member: avatar, name, phone and role, the task counters with the link to the full list, and
/// the tasks due today. Provides [EmployeeBloc].
class EmployeeScreen extends StatelessWidget {
  /// Id of the account to show.
  final String userId;

  /// Builds the screen.
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

/// Renders the profile for the current state.
class _EmployeeView extends StatelessWidget {
  /// Builds the view.
  const _EmployeeView();

  /// Opens the "⋯" menu: edit (the member form prefilled) and delete (after a confirmation).
  void _menu(BuildContext context, AppUser user) {
    /// Bloc of this screen, captured before the menu's own route is pushed.
    final bloc = context.read<EmployeeBloc>();
    final client = user.role == UserRole.client;
    ActionMenu.show(context, [
      (
        icon: AppIcons.edit,
        label: TrWords.cEdit.tr(),
        danger: false,
        onTap: () async {
          final saved = await context.push<bool>('${Routes.memberForm.path}?client=${client ? 1 : 0}&edit=${user.id}');
          if (saved == true) bloc.add(const EmployeeRefreshed());
        },
      ),
      (
        icon: AppIcons.trash,
        label: TrWords.mtDelete.tr(),
        danger: true,
        onTap: () => ConfirmDialog.show(
          context,
          icon: AppIcons.trash,
          title: TrWords.teamDelT.tr(),
          message: TrWords.teamDelD.tr(args: [user.name]),
          confirmText: TrWords.mtDelete.tr(),
          onConfirm: () async {
            bloc.add(const EmployeeDeleted());
            await bloc.stream.firstWhere((s) => !s.busy);
          },
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeeBloc, EmployeeState>(
      listenWhen: (prev, cur) => cur.response != null || cur.removed != null,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.removed != null) {
          showTopToast(
            context,
            icon: AppIcons.check,
            tone: StatusTone.primary,
            title: (state.removed! ? TrWords.teamDeleted : TrWords.teamDeactivated).tr(),
            message: '',
          );
          context.pop();
        }
      },
      builder: (context, state) {
        /// Bloc of this screen.
        final bloc = context.read<EmployeeBloc>();

        /// Loaded account; null while the first load runs or after it failed.
        final user = state.user;
        if (user == null) {
          return Scaffold(
            backgroundColor: theme.background,
            body: Column(
              children: [
                InnerBar(title: TrWords.emTitle.tr()),
                Expanded(
                  child: state.status.isError
                      ? EmptyView(
                          title: TrWords.cLoadFailed.tr(),
                          message: TrWords.cLoadFailedDesc.tr(),
                          icon: AppIcons.alert,
                          onRetry: () => bloc.add(const EmployeeStarted()),
                        )
                      : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 2)),
                ),
              ],
            ),
          );
        }

        /// Tasks due today, the ones the card lists.
        final today = state.items.where((t) => DateFormatter.daysTo(t.due) == 0).toList();
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: TrWords.emTitle.tr(),
                actions: [
                  IconButton(
                    onPressed: () => _menu(context, user),
                    icon: AppIcon(AppIcons.more, size: 26.sp, color: theme.primary),
                  ),
                ],
              ),
              Expanded(
                child: RefreshList(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + MediaQuery.of(context).padding.bottom),
                  gap: 22,
                  onRefresh: () async {
                    bloc.add(const EmployeeRefreshed());
                    await bloc.stream.firstWhere((s) => !s.refreshing);
                  },
                  children: [
                    Column(
                      children: [
                        UserAvatar(user.ref, size: 96.w),
                        12.h.height,
                        Text(
                          user.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(
                            fontSize: 22.sp,
                            height: 28 / 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        4.h.height,
                        if (user.phone.isNotEmpty)
                          Text(
                            PhoneFormatter.display(user.phone),
                            style: theme.textStyle.copyWith(color: theme.textSecondary, fontWeight: FontWeight.w400),
                          ),
                        8.h.height,
                        RolePill(user.role),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHead(
                          TrWords.emTasks.tr(),
                          action: TrWords.cMore.tr(),
                          chevron: true,
                          onAction: () => context.push(Routes.employeeTasks.of(user.id)),
                        ),
                        10.h.height,
                        CardWidget(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
                          decoration: theme.panelDecor,
                          child: Column(
                            children: [
                              CountRow(
                                first: true,
                                icon: AppIcons.tasks,
                                label: TrWords.emAll.tr(),
                                count: state.items.length,
                              ),
                              CountRow(
                                icon: AppIcons.checkc,
                                tone: StatusTone.primary,
                                label: TrWords.emDone.tr(),
                                count: state.items.where((t) => t.status == TaskStatus.done).length,
                              ),
                              CountRow(
                                icon: AppIcons.xc,
                                tone: StatusTone.error,
                                label: TrWords.emFailed.tr(),
                                count: state.items.where((t) => t.status == TaskStatus.fail).length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(TrWords.emToday.tr(), style: theme.fieldLabel),
                        10.h.height,
                        CardWidget(
                          padding: today.isEmpty ? EdgeInsets.all(14.w) : EdgeInsets.symmetric(horizontal: 14.w),
                          decoration: theme.panelDecor,
                          child: today.isEmpty
                              ? Row(
                                  children: [
                                    AppIcon.tile(AppIcons.cal, tone: StatusTone.primary, size: 44),
                                    12.w.width,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            TrWords.emNoTodayT.tr(),
                                            style: theme.textStyle.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                          2.h.height,
                                          Text(TrWords.emNoTodayD.tr(), style: theme.cardSubtitle),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    for (final (i, t) in today.indexed)
                                      ListRow(
                                        first: i == 0,
                                        chevron: false,
                                        titleSize: 15,
                                        leading: ToneCircle(t.status.icon, tone: t.status.tone),
                                        title: t.title,
                                        subtitle: t.status.title,
                                        trailing: Text(
                                          DateFormatter.time(t.due),
                                          style: theme.textStyle.copyWith(fontSize: 13.sp, color: theme.textSecondary),
                                        ),
                                        onTap: () => context.push(Routes.taskDetail.of(t.id)),
                                      ),
                                  ],
                                ),
                        ),
                      ],
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
