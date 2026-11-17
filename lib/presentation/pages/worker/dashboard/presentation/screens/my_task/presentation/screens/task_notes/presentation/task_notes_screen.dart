import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../bloc/bloc.dart';

/// Personal notes of an own task: one card per note (the newest tagged "Oxirgi"), swipe left to delete, and an
/// input bar to add a note. Provides [TaskNotesBloc].
class TaskNotesScreen extends StatelessWidget {
  /// Id of the task the notes belong to.
  final String taskId;

  /// Builds the screen for [taskId].
  const TaskNotesScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          TaskNotesBloc(repository: RepositoryProvider.of<TasksRepository>(ctx), taskId: taskId)
            ..add(const TaskNotesStarted()),
      child: const _TaskNotesView(),
    );
  }
}

/// Renders the list and owns the input controller.
class _TaskNotesView extends StatefulWidget {
  /// Builds the view.
  const _TaskNotesView();

  @override
  State<_TaskNotesView> createState() => _TaskNotesViewState();
}

/// Holds the text of the note being typed.
class _TaskNotesViewState extends State<_TaskNotesView> {
  /// Controller of the input bar.
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Sends the typed note and clears the bar; an empty note is ignored.
  void _send(TaskNotesBloc bloc) {
    /// Note text without surrounding spaces.
    final text = _input.text.trim();
    if (text.isEmpty) return;
    bloc.add(TaskNotesAdded(text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskNotesBloc, TaskNotesState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        /// Bloc of this screen.
        final bloc = context.read<TaskNotesBloc>();
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(title: TrWords.mtNotes.tr()),
              Expanded(
                child: state.status.isLoading
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3))
                    : state.status.isError
                    ? EmptyView(
                        title: TrWords.cLoadFailed.tr(),
                        message: TrWords.cLoadFailedDesc.tr(),
                        icon: AppIcons.alert,
                        onRetry: () => bloc.add(const TaskNotesStarted()),
                      )
                    : RefreshList(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                        gap: 10,
                        onRefresh: () async {
                          bloc.add(const TaskNotesStarted());
                          await bloc.stream.firstWhere((s) => !s.refreshing);
                        },
                        placeholder: EmptyView(title: TrWords.mtNoNotes.tr(), icon: AppIcons.edit),
                        children: [
                          for (final (i, note) in state.notes.indexed)
                            Dismissible(
                              key: ValueKey('${note.at.microsecondsSinceEpoch}-$i'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => bloc.add(TaskNotesRemoved(i)),
                              background: Container(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  width: 80.w,
                                  decoration: BoxDecoration(color: theme.red, borderRadius: 16.circular),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppIcon(AppIcons.trash, size: 20.sp, color: theme.cardColor),
                                      4.h.height,
                                      Text(
                                        TrWords.mtDelete.tr(),
                                        style: theme.textStyle.copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: theme.cardColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              child: CardWidget(
                                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                                decoration: theme.panelDecor,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.text,
                                      maxLines: 12,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textStyle.copyWith(height: 21 / 15, fontWeight: FontWeight.w400),
                                    ),
                                    6.h.height,
                                    Row(
                                      children: [
                                        Text(
                                          DateFormatter.due(note.at),
                                          style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
                                        ),
                                        if (i == state.notes.length - 1 && state.notes.length > 1) ...[
                                          6.w.width,
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: theme.primaryTint,
                                              borderRadius: 8.circular,
                                            ),
                                            child: Text(
                                              TrWords.mtLast.tr(),
                                              style: theme.textStyle.copyWith(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w700,
                                                color: theme.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16.w,
                  10.h,
                  16.w,
                  10.h + ScreenSize.bottomInset(context) + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(top: BorderSide(color: theme.line)),
                ),
                child: Container(
                  constraints: BoxConstraints(minHeight: 48.h),
                  padding: EdgeInsets.only(left: 14.w, right: 6.w),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: 12.circular,
                    border: Border.all(color: theme.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          style: theme.textStyle.copyWith(fontWeight: FontWeight.w400),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: TrWords.mtNoteHint.tr(),
                            hintStyle: theme.textStyle.copyWith(fontWeight: FontWeight.w400, color: theme.grayText),
                          ),
                          onSubmitted: (_) => _send(bloc),
                        ),
                      ),
                      8.w.width,
                      GestureDetector(
                        onTap: state.busy ? null : () => _send(bloc),
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
                          child: AppIcon(AppIcons.send, size: 18.sp, color: theme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
