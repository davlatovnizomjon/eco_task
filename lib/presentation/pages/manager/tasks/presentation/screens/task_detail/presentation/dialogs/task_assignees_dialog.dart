import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/infrastructure/dto/models/task_assignee.dart';

import '../widgets/assignee_line.dart';

/// Bottom sheet with every assignee of a task and their roles, opened from the "N more" link of the details.
class TaskAssigneesDialog extends StatelessWidget {
  /// All assignees of the task.
  final List<TaskAssignee> assignees;

  /// Builds the sheet.
  const TaskAssigneesDialog({super.key, required this.assignees});

  /// Opens the sheet for [assignees].
  static Future<void> show(BuildContext context, List<TaskAssignee> assignees) =>
      showBottomDialog<void>(TaskAssigneesDialog(assignees: assignees), context);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TrWords.tdAssignees.tr(),
            style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
          ),
          4.h.height,
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: assignees.length,
              itemBuilder: (_, i) => AssigneeLine(assignee: assignees[i], first: i == 0, height: 60),
            ),
          ),
        ],
      ),
    );
  }
}
