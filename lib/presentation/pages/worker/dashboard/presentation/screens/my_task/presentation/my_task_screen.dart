import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/auth_image.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/dialogs/action_menu.dart';
import 'package:eco_task/presentation/public/dialogs/confirm_dialog.dart';
import 'package:eco_task/presentation/public/dialogs/document_viewer.dart';
import 'package:eco_task/presentation/public/dialogs/photo_viewer.dart';
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

import '../bloc/bloc.dart';
import 'dialogs/maps_sheet.dart';
import 'dialogs/task_fail_sheet.dart';

/// The worker's own task: title, status, description, the details card (deadline, reminder, created, address,
/// photos, document), the latest personal note and the "not done" / "done" bar. Provides [MyTaskBloc].
class MyTaskScreen extends StatelessWidget {
  /// Id of the task to show.
  final String taskId;

  /// Builds the screen for [taskId].
  const MyTaskScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MyTaskBloc(
        repository: RepositoryProvider.of<TasksRepository>(ctx),
        chats: RepositoryProvider.of<ChatRepository>(ctx),
        taskId: taskId,
      )..add(const MyTaskStarted()),
      child: const _MyTaskView(),
    );
  }
}

/// Renders the task and keeps whether the long description is unfolded.
class _MyTaskView extends StatefulWidget {
  /// Builds the view.
  const _MyTaskView();

  @override
  State<_MyTaskView> createState() => _MyTaskViewState();
}

/// Holds the fold state of the description.
class _MyTaskViewState extends State<_MyTaskView> {
  /// Lines the folded description is clamped to.
  static const _foldedLines = 5;

  /// True while the whole description is shown.
  bool _expanded = false;

  /// Opens the "⋯" menu: share, or write to the manager who gave the task.
  void _menu(BuildContext context, TaskModel task) {
    /// Bloc of this screen, captured before the menu's own route is pushed.
    final bloc = context.read<MyTaskBloc>();
    ActionMenu.show(context, [
      (icon: AppIcons.share, label: TrWords.mtShare.tr(), danger: false, onTap: () {}),
      (
        icon: AppIcons.msg,
        label: TrWords.wkWriteManager.tr(),
        danger: false,
        onTap: () => bloc.add(const MyTaskChatOpened()),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyTaskBloc, MyTaskState>(
      listenWhen: (prev, cur) => cur.response != null || cur.closeScreen || cur.chatId != null,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.closeScreen) context.pop();
        if (state.chatId != null) context.push(Routes.chat.of(state.chatId!));
      },
      builder: (context, state) {
        /// Bloc of this screen.
        final bloc = context.read<MyTaskBloc>();

        /// Loaded task; null while the first load runs or after it failed.
        final task = state.task;
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(
                title: TrWords.mtTitle.tr(),
                actions: [
                  if (task != null)
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
                              onRetry: () => bloc.add(const MyTaskStarted()),
                            )
                          : const Padding(padding: EdgeInsets.all(16), child: SmartLoading()))
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                        gap: 22,
                        onRefresh: () async {
                          bloc.add(const MyTaskRefreshed());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        children: [_head(task), _info(context, task), if (task.comments.isNotEmpty) _note(task)],
                      ),
              ),
              if (task != null && task.status.isOpen)
                BottomActionBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: Btn(
                          text: TrWords.mtFailed.tr(),
                          height: 52.h,
                          onPressed: state.busy
                              ? null
                              : () async {
                                  /// Reason typed in the sheet; null when it was dismissed.
                                  final reason = await TaskFailSheet.show(context);
                                  if (reason != null) bloc.add(MyTaskFailed(reason));
                                },
                          decoration: BoxDecoration(color: theme.redBg, borderRadius: 16.circular),
                          textStyle: theme.textStyle.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: theme.red,
                          ),
                        ),
                      ),
                      10.w.width,
                      Expanded(
                        child: Btn(
                          text: TrWords.mtDone.tr(),
                          height: 52.h,
                          isLoading: state.busy,
                          onPressed: () => bloc.add(const MyTaskCompleted()),
                          decoration: BoxDecoration(color: theme.primary, borderRadius: 16.circular),
                          textStyle: theme.textStyle.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.onPrimary,
                          ),
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

  /// Title, status chip and the foldable description.
  Widget _head(TaskModel task) {
    /// Style of the description text.
    final body = theme.textStyle.copyWith(height: 22 / 15, fontWeight: FontWeight.w400, color: theme.textSecondary);
    return Column(
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
        10.h.height,
        Align(alignment: Alignment.centerLeft, child: StatusChip.task(task.status)),
        if (task.description.isNotEmpty) ...[
          10.h.height,
          LayoutBuilder(
            builder: (context, box) {
              /// Whether the text needs more than the folded lines at this width.
              final overflows = (TextPainter(
                text: TextSpan(text: task.description, style: body),
                maxLines: _foldedLines,
                textDirection: Directionality.of(context),
              )..layout(maxWidth: box.maxWidth)).didExceedMaxLines;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description,
                    maxLines: _expanded ? 200 : _foldedLines,
                    overflow: TextOverflow.ellipsis,
                    style: body,
                  ),
                  if (overflows) ...[
                    4.h.height,
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        (_expanded ? TrWords.mtLess : TrWords.mtMore).tr(),
                        style: theme.textStyle.copyWith(fontWeight: FontWeight.w600, color: theme.primary),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  /// "Details" card: deadline, reminder, created, address, photos and the document.
  Widget _info(BuildContext context, TaskModel task) {
    /// Whole hours left until the deadline; shown only for an open task due within a day.
    final hoursLeft = task.due.difference(DateTime.now()).inHours;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TrWords.mtInfo.tr(), style: theme.fieldLabel),
        10.h.height,
        CardWidget(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: theme.panelDecor,
          child: Column(
            children: [
              DetailRow(
                first: true,
                icon: AppIcons.cal,
                label: TrWords.mtDue.tr(),
                value: DateFormatter.due(task.due),
                bold: true,
                note: task.status.isOpen && hoursLeft > 0 && hoursLeft < 24
                    ? TrWords.mtHoursLeft.tr(args: ['$hoursLeft'])
                    : null,
              ),
              if (task.remindAt != null)
                DetailRow(
                  icon: AppIcons.bell,
                  label: TrWords.mtRemind.tr(),
                  value: TrWords.mtRemindAt.tr(args: [DateFormatter.time(task.remindAt!)]),
                ),
              if (task.createdAt != null)
                DetailRow(
                  icon: AppIcons.clock,
                  label: TrWords.mtCreated.tr(),
                  value: DateFormatter.dayTime(task.createdAt!),
                ),
              if (task.address.isNotEmpty)
                DetailRow(
                  icon: AppIcons.pin,
                  label: TrWords.mtAddress.tr(),
                  value: task.address,
                  onTap: () => MapsSheet.show(context, task.address),
                ),
              if (task.files > 0)
                DetailRow(
                  icon: AppIcons.image,
                  label: TrWords.mtPhotos.tr(),
                  onTap: () => PhotoViewer.show(context, count: task.files, files: task.images),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < task.files.clamp(0, 3); i++)
                        Align(
                          widthFactor: i == 0 ? 1 : 0.76,
                          child: Container(
                            width: 30.w,
                            height: 30.w,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: 7.circular,
                              border: Border.all(color: theme.cardColor, width: 2),
                            ),
                            child: AuthImage(task.images[i].id),
                          ),
                        ),
                      8.w.width,
                      Text(
                        TrWords.mtNPcs.tr(args: ['${task.files}']),
                        style: theme.textStyle.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              if (task.docName.isNotEmpty)
                DetailRow(
                  icon: AppIcons.file,
                  label: TrWords.mtDoc.tr(),
                  value: task.docName,
                  onTap: () => DocumentViewer.show(context, task.docName),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// "My notes": the latest note with the link to the whole list.
  Widget _note(TaskModel task) {
    /// The most recent note.
    final last = task.comments.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TrWords.mtNotes.tr(), style: theme.fieldLabel),
        10.h.height,
        CardWidget(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: theme.panelDecor,
          onTap: () async {
            /// Bloc of this screen, captured before leaving it.
            final bloc = context.read<MyTaskBloc>();
            await context.push(Routes.myTaskNotes.of(task.id));
            bloc.add(const MyTaskRefreshed());
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                last.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.copyWith(height: 21 / 15, fontWeight: FontWeight.w400),
              ),
              8.h.height,
              Row(
                children: [
                  Expanded(
                    child: Text(DateFormatter.due(last.at), style: theme.cardSubtitle.copyWith(fontSize: 12.sp)),
                  ),
                  Text(
                    TrWords.cMore.tr(),
                    style: theme.textStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.primary),
                  ),
                  2.w.width,
                  AppIcon(AppIcons.right, size: 16.sp, color: theme.primary),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
