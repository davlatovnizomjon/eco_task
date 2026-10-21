import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_due_filter.dart';
import 'package:eco_task/domain/common/enums/task_sort.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/infrastructure/dto/models/task_query.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../../bloc/bloc.dart';

/// Filter and sort sheet of the task list. It edits a local copy of the
/// opener's query and dispatches it to the opener's [TasksBloc] on apply.
class TasksFilterDialog extends StatefulWidget {
  /// People that can be filtered on, taken from the loaded tasks.
  final List<UserRef> people;

  /// Builds the sheet.
  const TasksFilterDialog({super.key, required this.people});

  @override
  State<TasksFilterDialog> createState() => _TasksFilterDialogState();
}

/// Holds the draft query the user edits before pressing apply.
class _TasksFilterDialogState extends State<TasksFilterDialog> {
  /// Draft filters; copied from the bloc's current query on open.
  late TaskQuery _draft = context.read<TasksBloc>().state.query;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TrWords.tasksState.tr(), style: theme.sectionLabel),
        8.h.height,
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final status in TaskStatus.values)
              FilterPill(
                label: status.title,
                icon: status.icon,
                selected: _draft.statuses.contains(status),
                onTap: () => setState(() {
                  final next = {..._draft.statuses};
                  if (!next.remove(status)) next.add(status);
                  _draft = _draft.copyWith(statuses: next);
                }),
              ),
          ],
        ),
        16.h.height,
        Text(TrWords.tasksDeadline.tr(), style: theme.sectionLabel),
        8.h.height,
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final due in const [TaskDueFilter.today, TaskDueFilter.week])
              FilterPill(
                label: due.title,
                selected: _draft.due == due,
                onTap: () => setState(() => _draft = _draft.copyWith(due: _draft.due == due ? TaskDueFilter.any : due)),
              ),
            FilterPill(
              label: TrWords.stOver.tr(),
              icon: AppIcons.alarm,
              selected: _draft.overdueOnly,
              onTap: () => setState(() => _draft = _draft.copyWith(overdueOnly: !_draft.overdueOnly)),
            ),
          ],
        ),
        if (widget.people.isNotEmpty) ...[
          16.h.height,
          Text(TrWords.tasksAssignee.tr(), style: theme.sectionLabel),
          8.h.height,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final person in widget.people)
                FilterPill(
                  label: person.firstName,
                  leading: UserAvatar(person, size: 24.w),
                  selected: _draft.who == person.id,
                  onTap: () => setState(
                    () => _draft = _draft.who == person.id
                        ? _draft.copyWith(clearWho: true)
                        : _draft.copyWith(who: person.id),
                  ),
                ),
            ],
          ),
        ],
        16.h.height,
        Text(TrWords.tasksSort.tr(), style: theme.sectionLabel),
        8.h.height,
        CardWidget(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, sort) in TaskSort.values.indexed)
                OptionTile(
                  title: sort.title,
                  first: i == 0,
                  onTap: () => setState(() => _draft = _draft.copyWith(sort: sort)),
                  trailing: AppIcon(
                    _draft.sort == sort ? AppIcons.checkc : AppIcons.eq,
                    color: _draft.sort == sort ? theme.primary : theme.line,
                  ),
                ),
            ],
          ),
        ),
        20.h.height,
        Row(
          children: [
            Expanded(
              child: Btn.unActive(
                text: TrWords.cClear.tr(),
                onPressed: () {
                  context.read<TasksBloc>().add(
                    TasksQueryChanged(
                      _draft.copyWith(statuses: {}, overdueOnly: false, clearWho: true, due: TaskDueFilter.any),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            10.w.width,
            Expanded(
              flex: 2,
              child: Btn(
                text: TrWords.cApprove.tr(),
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
