import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Compact task row of the dashboard and "today" list: an optional time, a status dot, title + subtitle and a
/// trailing chip. Rows of one group are drawn inside a single panel and separated by hairlines.
class TaskLine extends StatelessWidget {
  /// Time column shown before the dot (`09:00`, `—`); omitted when null.
  final String? time;

  /// Color of the status dot.
  final Color dot;

  /// Task title.
  final String title;

  /// Second line (assignees, deadline note).
  final String subtitle;

  /// Trailing status chip.
  final Widget trailing;

  /// Tap handler.
  final VoidCallback? onTap;

  /// True for the first row of a group (no top hairline).
  final bool first;

  /// Horizontal inset of the content (14 inside a panel, 2 on a flat list).
  final double inset;

  /// Builds the row.
  const TaskLine({
    super.key,
    this.time,
    required this.dot,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.first = false,
    this.inset = 14,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: inset.w, vertical: 11.h),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line)),
        ),
        child: Row(
          children: [
            if (time != null) ...[
              SizedBox(
                width: 44.w,
                child: Text(
                  time!,
                  style: theme.textStyle.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            12.w.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                  2.h.height,
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
                ],
              ),
            ),
            12.w.width,
            trailing,
          ],
        ),
      ),
    );
  }
}
