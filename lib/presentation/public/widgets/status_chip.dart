import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/expense_status.dart';
import 'package:eco_task/domain/common/enums/request_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';

import 'app_icon.dart';

/// Pill with a glyph and a label — status is never expressed by color alone.
/// Use the factory variants for the domain statuses.
class StatusChip extends StatelessWidget {
  /// Text of the pill.
  final String label;

  /// Color family of the pill.
  final StatusTone tone;

  /// SVG asset (an `AppIcons` constant) drawn before the label.
  final String? icon;

  /// True for the smaller 24 px pill used inside dense rows (12 px text, no glyph).
  final bool compact;

  /// Builds a pill from raw parts (e.g. the "overdue" pill).
  const StatusChip({super.key, required this.label, required this.tone, this.icon, this.compact = false});

  /// Dense 24 px pill of a task status (dashboard and day-list rows); [icon] hides the glyph when false.
  factory StatusChip.taskCompact(TaskStatus status, {bool icon = true}) =>
      StatusChip(label: status.title, tone: status.tone, icon: icon ? status.icon : null, compact: true);

  /// Dense 24 px amber "overdue" pill.
  factory StatusChip.overdueCompact() => StatusChip(label: TrWords.stOver.tr(), tone: StatusTone.warn, compact: true);

  /// Pill of a task status.
  factory StatusChip.task(TaskStatus status) => StatusChip(label: status.title, tone: status.tone, icon: status.icon);

  /// Pill of an expense review status.
  factory StatusChip.expense(ExpenseStatus status) =>
      StatusChip(label: status.title, tone: status.tone, icon: status.icon);

  /// Pill of a client request status.
  factory StatusChip.request(RequestStatus status) =>
      StatusChip(label: status.title, tone: status.tone, icon: status.icon);

  /// Amber "N days late" pill of an overdue task.
  factory StatusChip.overdue(int days) => StatusChip(
    label: TrWords.tasksOverdueBy.tr(args: ['$days']),
    tone: StatusTone.warn,
    icon: AppIcons.alarm,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (compact ? 24 : 26).h,
      padding: EdgeInsets.fromLTRB(icon == null ? 10.w : 8.w, 0, 10.w, 0),
      decoration: BoxDecoration(color: tone.bgColor, borderRadius: 13.circular),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[AppIcon(icon!, size: 14.sp, color: tone.color), 5.w.width],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.badgeText.copyWith(fontSize: compact ? 12.sp : null, color: tone.color),
            ),
          ),
        ],
      ),
    );
  }
}
