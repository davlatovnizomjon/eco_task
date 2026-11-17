import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/dto/models/task_model.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// One row of the admin task list: a status marker, the title, the first line of the description and a meta line —
/// deadline with the status pill (or the amber "N days late" note), the assignees' avatars at the right — and a
/// chevron. Rows are separated by a hairline that starts after the marker.
class TaskListRow extends StatelessWidget {
  /// Task drawn by the row.
  final TaskModel task;

  /// Tap handler.
  final VoidCallback onTap;

  /// True for the first row of the list (no top hairline).
  final bool first;

  /// Builds the row.
  const TaskListRow({super.key, required this.task, required this.onTap, this.first = false});

  /// Avatars shown before the "+N" counter.
  static const _maxAvatars = 3;

  @override
  Widget build(BuildContext context) {
    /// True for an open task past its deadline: amber marker and note, no status pill.
    final late = task.isOverdue;

    /// Color family of the marker and the pill.
    final tone = late ? StatusTone.warn : task.status.tone;

    /// Assignees hidden behind the "+N" counter.
    final extra = task.assignees.length - _maxAvatars;
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          if (!first)
            Positioned(
              top: 0,
              left: 46.w,
              right: 0,
              child: Container(height: 0.5, color: theme.line),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                ToneCircle(late ? AppIcons.alarm : task.status.icon, tone: tone),
                12.w.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyle.copyWith(fontSize: 16.sp, height: 21 / 16, fontWeight: FontWeight.w600),
                      ),
                      if (task.description.isNotEmpty) ...[
                        2.h.height,
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.cardSubtitle.copyWith(color: theme.textSecondary),
                        ),
                      ],
                      4.h.height,
                      Row(
                        children: [
                          AppIcon(AppIcons.clock, size: 14.sp, color: late ? theme.warn : theme.textSecondary),
                          4.w.width,
                          Flexible(
                            child: Text(
                              late
                                  ? TrWords.cDaysLate.tr(args: ['${task.lateDays}'])
                                  : DateFormatter.dayShortTime(task.due),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textStyle.copyWith(
                                fontSize: 13.sp,
                                color: late ? theme.warn : theme.textSecondary,
                              ),
                            ),
                          ),
                          if (!late) ...[
                            8.w.width,
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: tone.color.withValues(alpha: 0.12),
                                borderRadius: 10.circular,
                              ),
                              child: Text(
                                task.status.title,
                                style: theme.textStyle.copyWith(
                                  fontSize: 12.sp,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w600,
                                  color: tone.color,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          for (final (i, a) in task.assignees.take(_maxAvatars).indexed)
                            Align(
                              widthFactor: i == 0 ? 1 : 0.8,
                              child: Container(
                                padding: 2.w.all,
                                decoration: BoxDecoration(color: theme.background, shape: BoxShape.circle),
                                child: UserAvatar(a.user, size: 22.w),
                              ),
                            ),
                          if (extra > 0)
                            Align(
                              widthFactor: 0.8,
                              child: Container(
                                width: 26.w,
                                height: 26.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: theme.cardColorLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.background, width: 2),
                                ),
                                child: Text(
                                  '+$extra',
                                  style: theme.textStyle.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                8.w.width,
                AppIcon(AppIcons.right, size: 16.sp, color: theme.grayText.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
