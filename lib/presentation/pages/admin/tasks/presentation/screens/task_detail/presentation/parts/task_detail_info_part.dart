import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import 'package:eco_task/infrastructure/dto/models/app_user.dart';

/// Top of the task details: title block, the worker's own quota, the due-date
/// card, the assignees (boss) and the submitted result.
class TaskDetailInfoPart extends StatelessWidget {
  /// The task being shown.
  final TaskModel task;

  /// The signed-in account; decides what the boss/worker views show.
  final AppUser me;

  /// Builds the info section.
  const TaskDetailInfoPart({super.key, required this.task, required this.me});

  @override
  Widget build(BuildContext context) {
    final boss = me.role.isBoss;
    final mine = task.assigneeOf(me.id);
    final late = task.isOverdue;
    return Column(
      spacing: 20.h,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.title, style: theme.screenTitle.copyWith(fontSize: 22.sp, height: 1.25)),
            10.h.height,
            Wrap(
              spacing: 10.w,
              runSpacing: 6.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip.task(task.status),
                if (late) StatusChip.overdue(task.lateDays),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(task.priority.icon, size: 16.sp, color: task.priority.tone.color),
                    4.w.width,
                    Text(task.priority.title, style: theme.badgeText.copyWith(color: task.priority.tone.color)),
                  ],
                ),
                if (task.category.isNotEmpty) Text('· ${task.category}', style: theme.cardSubtitle),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              12.h.height,
              Text(
                task.description,
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.copyWith(fontWeight: FontWeight.w400, color: theme.textSecondary, height: 1.45),
              ),
            ],
          ],
        ),
        if (!boss && mine != null && mine.share > 0)
          CardWidget(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(TrWords.tasksMyShare.tr(), style: theme.cardTitle.copyWith(fontSize: 15.sp)),
                    ),
                    Text(TrWords.cOf.tr(args: ['${mine.done}', '${mine.share}']), style: theme.cardTitle),
                  ],
                ),
                10.h.height,
                ClipRRect(
                  borderRadius: 3.circular,
                  child: LinearProgressIndicator(
                    value: (mine.done / mine.share).clamp(0, 1).toDouble(),
                    minHeight: 6.h,
                    backgroundColor: theme.cardColorLight,
                    color: theme.primary,
                  ),
                ),
              ],
            ),
          ),
        CardWidget(
          child: Column(
            children: [
              InfoRow(
                label: TrWords.formDue.tr(),
                icon: AppIcons.cal,
                value:
                    '${DateFormatter.due(task.due)}${task.status.isOpen ? ' · ${late ? TrWords.cDaysLate.tr(args: ['${task.lateDays}']) : TrWords.cDaysLeft.tr(args: ['${DateFormatter.daysTo(task.due).clamp(0, 999)}'])}' : ''}',
                valueColor: late ? theme.warn : null,
              ),
              if (task.expected.isNotEmpty)
                InfoRow(label: TrWords.tasksExpected.tr(), icon: AppIcons.flag, value: task.expected),
              if (boss) InfoRow(label: TrWords.tasksCreatedBy.tr(), icon: AppIcons.user, value: task.createdBy.name),
            ],
          ),
        ),
        if (boss)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      TrWords.tasksAssignees.tr(args: ['${task.assignees.length}']),
                      style: theme.sectionLabel,
                    ),
                  ),
                  if (task.ratio != null)
                    Text(
                      TrWords.tasksTotal.tr(args: ['${task.totalDone}', '${task.totalShare}']),
                      style: theme.cardSubtitle,
                    ),
                ],
              ),
              8.h.height,
              CardWidget(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, a) in task.assignees.indexed)
                      OptionTile(
                        title: a.user.name,
                        first: i == 0,
                        subtitle: a.share > 0 ? TrWords.tasksShare.tr(args: ['${a.share}']) : null,
                        leading: UserAvatar(a.user, size: 36.w),
                        onTap: () => context.push(Routes.employee.of(a.user.id)),
                        trailing: a.share > 0
                            ? SizedBox(
                                width: 90.w,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(TrWords.cOf.tr(args: ['${a.done}', '${a.share}']), style: theme.badgeText),
                                    4.h.height,
                                    ClipRRect(
                                      borderRadius: 3.circular,
                                      child: LinearProgressIndicator(
                                        value: (a.done / a.share).clamp(0, 1).toDouble(),
                                        minHeight: 6.h,
                                        backgroundColor: theme.cardColorLight,
                                        color: theme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        if (task.result.isNotEmpty)
          CardWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TrWords.revSubmittedResult.tr(), style: theme.sectionLabel),
                6.h.height,
                Text(
                  task.result,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(fontWeight: FontWeight.w400, height: 1.4),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
