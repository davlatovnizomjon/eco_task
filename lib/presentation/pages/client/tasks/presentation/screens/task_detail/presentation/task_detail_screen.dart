import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/auth_image.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/dialogs/action_menu.dart';
import 'package:eco_task/presentation/public/dialogs/confirm_dialog.dart';
import 'package:eco_task/presentation/public/dialogs/photo_viewer.dart';
import 'package:eco_task/presentation/public/dialogs/reject_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/detail_row.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';
import 'dialogs/task_assignees_dialog.dart';
import 'widgets/assignee_line.dart';

/// Details of one order for the client: title and description, the facts card (status, deadline, address,
/// price, creator, created), photos and the assignees with their roles. The "⋯" menu edits or deletes the task; a
/// result waiting for a decision adds the reject / approve bar. Provides [TaskDetailBloc].
class TaskDetailScreen extends StatelessWidget {
  /// Id of the task to show.
  final String taskId;

  /// Builds the screen.
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

/// Renders the task and wires its actions.
class _TaskDetailView extends StatelessWidget {
  /// Builds the view.
  const _TaskDetailView();

  /// Assignees listed on the screen before the "N more" link.
  static const _shown = 3;

  /// Opens the "⋯" menu: edit, delete.
  void _menu(BuildContext context, TaskModel task) {
    /// Bloc of this screen, captured before the menu's own route is pushed.
    final bloc = context.read<TaskDetailBloc>();
    ActionMenu.show(context, [
      (
        icon: AppIcons.edit,
        label: TrWords.cEdit.tr(),
        danger: false,
        onTap: () async {
          await context.push(Routes.taskEdit.of(task.id));
          bloc.add(const TaskDetailRefreshed());
        },
      ),
      (
        icon: AppIcons.trash,
        label: TrWords.mtDelete.tr(),
        danger: true,
        onTap: () => ConfirmDialog.show(
          context,
          icon: AppIcons.trash,
          title: TrWords.clDelT.tr(),
          message: TrWords.clDelD.tr(),
          confirmText: TrWords.mtDelete.tr(),
          onConfirm: () async {
            bloc.add(const TaskDetailDeleted());
            await bloc.stream.firstWhere((s) => !s.busy);
          },
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailBloc, TaskDetailState>(
      listenWhen: (prev, cur) => cur.response != null || cur.closeScreen,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.closeScreen) context.pop();
      },
      builder: (context, state) {
        /// Bloc of this screen.
        final bloc = context.read<TaskDetailBloc>();

        /// Loaded task; null while the first load runs or after it failed.
        final task = state.task;
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: TrWords.clDetail.tr(),
                actions: [
                  // Only an order nobody has started can be edited or deleted (the backend enforces it too).
                  if (task != null && task.status == TaskStatus.fresh)
                    IconButton(
                      onPressed: () => _menu(context, task),
                      icon: AppIcon(AppIcons.more, size: 26.sp, color: theme.primary),
                    ),
                ],
              ),
              Expanded(
                child: task == null
                    ? (state.status.isError
                          ? EmptyView(
                              title: TrWords.cLoadFailed.tr(),
                              message: TrWords.cLoadFailedDesc.tr(),
                              icon: AppIcons.alert,
                              onRetry: () => bloc.add(const TaskDetailStarted()),
                            )
                          : const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3)))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                        gap: 22,
                        onRefresh: () async {
                          bloc.add(const TaskDetailRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        children: [
                          _head(task),
                          _facts(task),
                          if (task.files > 0) _photos(context, task),
                          _people(context, task),
                        ],
                      ),
              ),
              if (task != null && task.status == TaskStatus.rev)
                BottomActionBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: Btn.danger(
                          text: TrWords.cReject.tr(),
                          icon: AppIcons.x,
                          onPressed: () => showBottomDialog(
                            RejectDialog(
                              assigneeName: task.assignees.isEmpty ? '' : task.assignees.first.user.firstName,
                              onSubmit: (reason, extend) =>
                                  bloc.add(TaskDetailReturned(reason: reason, extend: extend)),
                            ),
                            context,
                            title: TrWords.revRejectTitle.tr(),
                          ),
                        ),
                      ),
                      8.w.width,
                      Expanded(
                        child: Btn(
                          text: TrWords.cApprove.tr(),
                          icon: AppIcons.check,
                          isLoading: state.busy,
                          onPressed: () => bloc.add(const TaskDetailApproved()),
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

  /// Title and description.
  Widget _head(TaskModel task) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        task.title,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: theme.textStyle.copyWith(
          fontSize: 22.sp,
          height: 28 / 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      if (task.description.isNotEmpty) ...[
        10.h.height,
        Text(
          task.description,
          maxLines: 12,
          overflow: TextOverflow.ellipsis,
          style: theme.textStyle.copyWith(height: 22 / 15, fontWeight: FontWeight.w400, color: theme.textSecondary),
        ),
      ],
    ],
  );

  /// Facts card: status, deadline, address, price, creator and creation date; rows without data are hidden.
  Widget _facts(TaskModel task) => CardWidget(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    decoration: theme.panelDecor,
    child: Column(
      children: [
        DetailRow(
          first: true,
          icon: task.status.icon,
          label: TrWords.tdStatus.tr(),
          trailing: StatusChip.task(task.status),
        ),
        DetailRow(
          icon: AppIcons.cal,
          label: TrWords.mtDue.tr(),
          value: DateFormatter.dayShortTime(task.due),
          bold: true,
        ),
        if (task.address.isNotEmpty) DetailRow(icon: AppIcons.pin, label: TrWords.mtAddress.tr(), value: task.address),
        if (task.reward > 0)
          DetailRow(
            icon: AppIcons.coins,
            label: TrWords.tdPrice.tr(),
            value: MoneyFormatter.amount(task.reward, task.currency),
            bold: true,
          ),
        DetailRow(icon: AppIcons.user, label: TrWords.tdCreator.tr(), value: task.createdBy.name),
        if (task.createdAt != null)
          DetailRow(
            icon: AppIcons.clock,
            label: TrWords.tdCreatedAt.tr(),
            value: DateFormatter.dayShortTime(task.createdAt!),
          ),
      ],
    ),
  );

  /// "Photos": a row of square thumbnails; a tap opens the viewer on that photo.
  Widget _photos(BuildContext context, TaskModel task) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(TrWords.mtPhotos.tr(), style: theme.fieldLabel),
      10.h.height,
      SizedBox(
        height: 72.w,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: task.files,
          separatorBuilder: (_, _) => 8.w.width,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => PhotoViewer.show(context, count: task.files, initial: i, files: task.images),
            child: SizedBox(
              width: 72.w,
              child: AuthImage(task.images[i].id, radius: 10.r),
            ),
          ),
        ),
      ),
    ],
  );

  /// "Assignees": the first three with their role pills and the link to the whole list.
  Widget _people(BuildContext context, TaskModel task) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(TrWords.tdAssignees.tr(), style: theme.fieldLabel),
      10.h.height,
      CardWidget(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: theme.panelDecor,
        child: task.assignees.isEmpty
            ? Container(
                constraints: BoxConstraints(minHeight: 56.h),
                alignment: Alignment.centerLeft,
                child: Text(TrWords.tdNoAssignees.tr(), style: theme.cardSubtitle),
              )
            : Column(
                children: [
                  for (final (i, a) in task.assignees.take(_shown).indexed) AssigneeLine(assignee: a, first: i == 0),
                  if (task.assignees.length > _shown)
                    InkWell(
                      onTap: () => TaskAssigneesDialog.show(context, task.assignees),
                      child: Container(
                        constraints: BoxConstraints(minHeight: 48.h),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: theme.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                TrWords.tdMorePeople.tr(args: ['${task.assignees.length - _shown}']),
                                style: theme.textStyle.copyWith(fontWeight: FontWeight.w600, color: theme.primary),
                              ),
                            ),
                            AppIcon(AppIcons.right, size: 18.sp, color: theme.primary),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    ],
  );
}
