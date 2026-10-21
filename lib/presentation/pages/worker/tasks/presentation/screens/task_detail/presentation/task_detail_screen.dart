import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/dialogs/reject_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';
import 'dialogs/task_comment_dialog.dart';
import 'dialogs/task_progress_dialog.dart';
import 'parts/task_detail_activity_part.dart';
import 'parts/task_detail_info_part.dart';
import 'parts/task_detail_money_part.dart';

/// Details of one task for every role: a boss reviews, edits and cancels, a
/// worker updates progress, comments, adds expenses and submits the result.
/// Provides [TaskDetailBloc] over the app-wide [TasksRepository].
class TaskDetailScreen extends StatelessWidget {
  /// Id of the task to show.
  final String taskId;

  /// Builds the details screen for [taskId].
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          TaskDetailBloc(repository: RepositoryProvider.of<TasksRepository>(ctx), taskId: taskId)
            ..add(const TaskDetailStarted()),
      child: const _TaskDetailView(),
    );
  }
}

/// Renders the task, its sections and the role-dependent bottom actions.
class _TaskDetailView extends StatelessWidget {
  /// Builds the details body.
  const _TaskDetailView();

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (prev, cur) => cur.response != null || cur.closeScreen,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.closeScreen) context.pop();
      },
      builder: (context, state) {
        final bloc = context.read<TaskDetailBloc>();
        final task = state.task;
        if (task == null) {
          return ScreenShell(
            title: bloc.taskId,
            child: state.status.isError
                ? EmptyView(
                    title: TrWords.cLoadFailed.tr(),
                    message: TrWords.cLoadFailedDesc.tr(),
                    icon: AppIcons.alert,
                    onRetry: () => bloc.add(const TaskDetailStarted()),
                  )
                : const SmartLoading(count: 3),
          );
        }
        final boss = me.role.isBoss;
        final mine = task.assigneeOf(me.id);
        // Role- and status-dependent bottom actions: approve/return for a submitted
        // task, edit/cancel for an open one (boss), the worker's actions for an
        // open task they take part in. Stays null when there is nothing to do.
        Widget? bottom;
        if (boss && task.status == TaskStatus.rev) {
          bottom = Row(
            children: [
              Expanded(
                child: Btn.danger(
                  text: TrWords.cReject.tr(),
                  icon: AppIcons.x,
                  onPressed: () => showBottomDialog(
                    RejectDialog(
                      assigneeName: task.assignees.first.user.firstName,
                      onSubmit: (reason, extend) => bloc.add(TaskDetailReturned(reason: reason, extend: extend)),
                    ),
                    context,
                    title: TrWords.revRejectTitle.tr(),
                  ),
                ),
              ),
              12.w.width,
              Expanded(
                child: Btn(
                  text: TrWords.cApprove.tr(),
                  icon: AppIcons.check,
                  onPressed: () => bloc.add(const TaskDetailApproved()),
                ),
              ),
            ],
          );
        }
        if (boss && task.status.isOpen) {
          bottom = Row(
            children: [
              Expanded(
                child: Btn.unActive(
                  text: TrWords.tasksCancelTask.tr(),
                  icon: AppIcons.xc,
                  onPressed: () => showCenterDialog(
                    PublicDialog.confirm(
                      title: TrWords.tasksCancelTask.tr(),
                      subTitle: task.title,
                      activeBtnText: TrWords.cOk.tr(),
                      unActiveBtnText: TrWords.cCancel.tr(),
                      onActiveBtnPressed: () => bloc.add(const TaskDetailCanceled()),
                    ),
                    context,
                  ),
                ),
              ),
              12.w.width,
              Expanded(
                child: Btn(
                  text: TrWords.cEdit.tr(),
                  icon: AppIcons.edit,
                  onPressed: () => context.push(Routes.taskEdit.of(task.id)),
                ),
              ),
            ],
          );
        }
        if (!boss && mine != null && task.status.isOpen) {
          bottom = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Btn.unActive(
                      text: TrWords.tasksStateBtn.tr(),
                      icon: AppIcons.edit,
                      height: 40.h,
                      onPressed: () => showBottomDialog(
                        BlocProvider.value(
                          value: bloc,
                          child: TaskProgressDialog(share: mine.share, done: mine.done),
                        ),
                        context,
                        title: TrWords.wUpdateProgress.tr(),
                      ),
                    ),
                  ),
                  8.w.width,
                  Expanded(
                    child: Btn.unActive(
                      text: TrWords.tasksCommentBtn.tr(),
                      icon: AppIcons.msg,
                      height: 40.h,
                      onPressed: () => showBottomDialog(
                        BlocProvider.value(value: bloc, child: const TaskCommentDialog()),
                        context,
                        title: TrWords.wAddComment.tr(),
                      ),
                    ),
                  ),
                  8.w.width,
                  Expanded(
                    child: Btn.unActive(
                      text: TrWords.tasksExpenseBtn.tr(),
                      icon: AppIcons.receipt,
                      height: 40.h,
                      onPressed: () => context.push(Routes.expenseForm.of(task.id)),
                    ),
                  ),
                ],
              ),
              8.h.height,
              Btn(
                text: TrWords.tasksSendResult.tr(),
                icon: AppIcons.send,
                onPressed: () => context.push(Routes.resultSubmit.of(task.id)),
              ),
            ],
          );
        }
        return ScreenShell(
          title: task.code,
          padding: EdgeInsets.zero,
          actions: [
            IconButton(
              onPressed: () => context.push(Routes.taskChat.of(task.id)),
              icon: AppIcon(AppIcons.msg, color: theme.text),
            ),
            if (boss && task.status.isOpen)
              IconButton(
                onPressed: () => context.push(Routes.taskEdit.of(task.id)),
                icon: AppIcon(AppIcons.edit, color: theme.text),
              ),
          ],
          bottomBar: bottom,
          child: RefreshList(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            gap: 20,
            onRefresh: () async {
              bloc.add(const TaskDetailRefreshed());
              await bloc.stream.firstWhere((s) => !s.refreshing);
            },
            children: [
              TaskDetailInfoPart(task: task, me: me),
              TaskDetailMoneyPart(task: task, me: me),
              TaskDetailActivityPart(task: task, me: me),
            ],
          ),
        );
      },
    );
  }
}
