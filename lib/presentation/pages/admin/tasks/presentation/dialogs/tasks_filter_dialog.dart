import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_due_filter.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/presentation/public/dialogs/date_range_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../../bloc/bloc.dart';
import 'assignee_filter_dialog.dart';

/// Filter sheet of the tasks tab: one status, one deadline window (or a hand-picked range) and any number of
/// assignees. Edits a draft [TaskQuery]; nothing is sent until "show result" is pressed. Reads its opener's
/// [TasksBloc].
class TasksFilterDialog extends StatefulWidget {
  /// Builds the sheet.
  const TasksFilterDialog({super.key});

  /// Opens the sheet over the tasks tab, sharing the tab's [bloc].
  static Future<void> show(BuildContext context, TasksBloc bloc) =>
      showBottomDialog<void>(BlocProvider.value(value: bloc, child: const TasksFilterDialog()), context);

  @override
  State<TasksFilterDialog> createState() => _TasksFilterDialogState();
}

/// Holds the draft query.
class _TasksFilterDialogState extends State<TasksFilterDialog> {
  /// The query being edited, initialized from the bloc's current one.
  late TaskQuery _draft = context.read<TasksBloc>().state.query;

  /// Status choices in tab order; null stands for "all" and the overdue entry is a flag, not a status.
  static const List<TaskStatus?> _statuses = [
    null,
    TaskStatus.fresh,
    TaskStatus.prog,
    null,
    TaskStatus.done,
    TaskStatus.fail,
  ];

  /// Index of the selected status chip: 0 all, 3 overdue, else the matching status.
  int get _statusIndex {
    if (_draft.overdueOnly) return 3;
    if (_draft.statuses.length != 1) return 0;

    /// Position of the single selected status among the chips.
    final i = _statuses.indexOf(_draft.statuses.first);
    return i < 0 ? 0 : i;
  }

  /// Label of status chip [i].
  String _statusLabel(int i) => switch (i) {
    0 => TrWords.cAll.tr(),
    3 => TrWords.dashOverdue.tr(),
    4 => TrWords.tlDoneTab.tr(),
    5 => TrWords.tlFailTab.tr(),
    _ => _statuses[i]!.title,
  };

  /// Opens the range picker and stores the picked range as the deadline filter.
  Future<void> _pickRange() async {
    /// Range picked in the sheet; null when it was dismissed.
    final range = await DateRangeDialog.show(
      context,
      initial: _draft.from == null ? null : DateTimeRange(start: _draft.from!, end: _draft.to ?? _draft.from!),
    );
    if (range == null) return;
    setState(() => _draft = _draft.copyWith(due: TaskDueFilter.range, from: range.start, to: range.end));
  }

  /// Opens the assignee picker and stores the picked ids.
  Future<void> _pickPeople() async {
    /// Bloc of the tasks tab; also the source of the staff list.
    final bloc = context.read<TasksBloc>()..add(const TasksStaffRequested());

    /// Ids picked in the sheet; null when it was dismissed.
    final picked = await AssigneeFilterDialog.show(context, bloc, _draft.people);
    if (picked != null) setState(() => _draft = _draft.copyWith(people: picked));
  }

  /// Caption above a block of the sheet.
  Widget _label(String text) => Padding(
    padding: 10.h.bottom,
    child: Text(text, style: theme.fieldLabel),
  );

  @override
  Widget build(BuildContext context) {
    /// Staff already loaded by the bloc, used to draw the picked assignees.
    final picked = context.watch<TasksBloc>().state.staff.where((u) => _draft.people.contains(u.id)).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TrWords.fltTitle.tr(),
          style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
        ),
        16.h.height,
        _label(TrWords.tasksState.tr()),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (var i = 0; i < _statuses.length; i++)
              FilterPill(
                accent: true,
                label: _statusLabel(i),
                selected: _statusIndex == i,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(
                    statuses: _statuses[i] == null ? {} : {_statuses[i]!},
                    overdueOnly: i == 3,
                  ),
                ),
              ),
          ],
        ),
        20.h.height,
        _label(TrWords.tasksDeadline.tr()),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final due in const [TaskDueFilter.today, TaskDueFilter.week, TaskDueFilter.month])
              FilterPill(
                accent: true,
                label: due.title,
                selected: _draft.due == due,
                onTap: () => setState(() => _draft = _draft.copyWith(due: _draft.due == due ? TaskDueFilter.any : due)),
              ),
            if (_draft.due == TaskDueFilter.range && _draft.from != null)
              FilterPill(
                accent: true,
                selected: true,
                icon: AppIcons.cal,
                trailingIcon: AppIcons.x,
                label: '${DateFormatter.dayShort(_draft.from!)} — ${DateFormatter.dayShort(_draft.to ?? _draft.from!)}',
                onTap: () => setState(() => _draft = _draft.copyWith(due: TaskDueFilter.any)),
              )
            else
              FilterPill(label: TrWords.fltPickDate.tr(), icon: AppIcons.cal, onTap: _pickRange),
          ],
        ),
        20.h.height,
        _label(TrWords.tasksAssignee.tr()),
        CardWidget(
          onTap: _pickPeople,
          padding: EdgeInsets.fromLTRB(14.w, 0, 12.w, 0),
          height: 52.h,
          decoration: theme.panelDecor,
          child: Row(
            children: [
              if (picked.isEmpty)
                AppIcon(AppIcons.users, size: 22.sp, color: theme.grayText)
              else
                AvatarStack([for (final u in picked) u.ref], size: 26.w),
              10.w.width,
              Expanded(
                child: Text(
                  picked.isEmpty ? TrWords.fltAllPeople.tr() : picked.map((u) => u.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(
                    fontWeight: FontWeight.w400,
                    color: picked.isEmpty ? theme.textSecondary : theme.text,
                  ),
                ),
              ),
              if (_draft.people.isNotEmpty) ...[
                8.w.width,
                Text(
                  TrWords.mtNPcs.tr(args: ['${_draft.people.length}']),
                  style: theme.textStyle.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600, color: theme.primary),
                ),
              ],
              6.w.width,
              AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText),
            ],
          ),
        ),
        24.h.height,
        Row(
          children: [
            Expanded(
              flex: 10,
              child: Btn.unActive(
                text: TrWords.cClear.tr(),
                height: 52.h,
                onPressed: () => setState(
                  () => _draft = _draft.copyWith(
                    statuses: {},
                    overdueOnly: false,
                    clearWho: true,
                    people: {},
                    due: TaskDueFilter.any,
                  ),
                ),
              ),
            ),
            10.w.width,
            Expanded(
              flex: 16,
              child: Btn(
                text: TrWords.fltShow.tr(),
                height: 52.h,
                onPressed: () {
                  context.read<TasksBloc>().add(TasksQueryChanged(_draft));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
