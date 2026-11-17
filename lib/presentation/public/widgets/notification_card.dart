import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Bordered card of one inbox entry: a bold title with the time (green and a dot while unread) and a two-line
/// message. Tapping it opens the entry.
class NotificationCard extends StatelessWidget {
  /// Bold first line.
  final String title;

  /// Relative time at the right of the title.
  final String time;

  /// Body text, clamped to two lines.
  final String message;

  /// True for an entry not read yet.
  final bool unread;

  /// Tap handler.
  final VoidCallback onTap;

  /// Builds the card.
  const NotificationCard({
    super.key,
    required this.title,
    required this.time,
    required this.message,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: theme.cardDecor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
                8.w.width,
                Text(
                  time,
                  style: theme.textStyle.copyWith(
                    fontSize: 13.sp,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    color: unread ? theme.primary : theme.grayText,
                  ),
                ),
                if (unread) ...[
                  8.w.width,
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
            4.h.height,
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyle.copyWith(
                fontSize: 14.sp,
                height: 19 / 14,
                fontWeight: FontWeight.w400,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
