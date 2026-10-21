import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import 'app_icon.dart';
import 'card_widget.dart';
import 'status_chip.dart';
import 'user_avatar.dart';

/// List card of one task: id, priority, title, status, progress, deadline,
/// reward and assignees. Shared by the dashboard, task lists and worker home.
class TaskCard extends StatelessWidget {
  /// The task to show.
  final TaskModel task;

  /// Opens the task.
  final VoidCallback onTap;

  /// Builds the card.
  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final late = task.isOverdue;
    final ratio = task.ratio;
    return CardWidget(
      onTap: onTap,
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(task.code, style: theme.fieldLabel.copyWith(color: theme.grayText)),
              const Spacer(),
              if (task.status.isOpen) ...[
                AppIcon(task.priority.icon, size: 16.sp, color: task.priority.tone.color),
                4.w.width,
                Text(task.priority.title, style: theme.badgeText.copyWith(color: task.priority.tone.color)),
              ],
            ],
          ),
          6.h.height,
          Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.cardTitle),
          10.h.height,
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip.task(task.status),
              if (late) StatusChip.overdue(task.lateDays),
              if (ratio != null)
                Text(TrWords.cOf.tr(args: ['${task.totalDone}', '${task.totalShare}']), style: theme.cardSubtitle),
            ],
          ),
          if (ratio != null && task.status == TaskStatus.prog) ...[
            10.h.height,
            ClipRRect(
              borderRadius: 3.circular,
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6.h,
                backgroundColor: theme.cardColorLight,
                color: theme.primary,
              ),
            ),
          ],
          10.h.height,
          Row(
            children: [
              AppIcon(AppIcons.cal, size: 16.sp, color: late ? theme.warn : theme.grayText),
              4.w.width,
              Flexible(
                child: Text(
                  DateFormatter.due(task.due),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle.copyWith(color: late ? theme.warn : null),
                ),
              ),
              if (task.reward > 0) ...[
                12.w.width,
                AppIcon(AppIcons.coins, size: 16.sp, color: theme.grayText),
                4.w.width,
                Text(MoneyFormatter.display(task.reward), style: theme.cardSubtitle),
              ],
              const Spacer(),
              if (task.assignees.isNotEmpty) AvatarStack([for (final a in task.assignees) a.user]),
            ],
          ),
        ],
      ),
    );
  }
}
