import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/list_row.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// "Today's tasks" panel of the dashboard: one row per task due today or overdue — a status marker, the title,
/// the assignees and the deadline (time, or days late in amber).
class TodayTasksCard extends StatelessWidget {
  /// Tasks due today or overdue; never empty.
  final List<TaskModel> tasks;

  /// Builds the panel.
  const TodayTasksCard({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: theme.panelDecor,
      child: Column(
        children: [
          for (final (i, task) in tasks.indexed)
            ListRow(
              first: i == 0,
              chevron: false,
              titleSize: 15,
              onTap: () => context.push(Routes.taskDetail.of(task.id)),
              leading: ToneCircle(
                task.isOverdue ? AppIcons.alarm : task.status.icon,
                tone: task.isOverdue ? StatusTone.warn : task.status.tone,
              ),
              title: task.title,
              subtitle: task.assignees.isEmpty ? task.code : task.assignees.map((a) => a.user.firstName).join(', '),
              trailing: Text(
                task.isOverdue
                    ? TrWords.dashDaysLateShort.tr(args: ['${task.lateDays}'])
                    : DateFormatter.time(task.due),
                style: theme.textStyle.copyWith(
                  fontSize: 13.sp,
                  fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.w500,
                  color: task.isOverdue ? theme.warn : theme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
