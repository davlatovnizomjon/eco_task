import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Row of the notifications inbox: round kind marker, title + time, message and an unread dot.
class NotificationRow extends StatelessWidget {
  /// Round leading marker (`ToneCircle`).
  final Widget leading;

  /// Headline of the notification.
  final String title;

  /// Time label at the right of the headline.
  final String time;

  /// Message text under the headline.
  final String message;

  /// Whether the notification is unread: bold title, green time and a dot.
  final bool unread;

  /// Tap handler.
  final VoidCallback? onTap;

  /// True for the first row of a group (no top hairline).
  final bool first;

  /// Builds the row.
  const NotificationRow({
    super.key,
    required this.leading,
    required this.title,
    required this.time,
    required this.message,
    this.unread = false,
    this.onTap,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            12.w.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
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
                          fontSize: 12.sp,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread ? theme.primary : theme.grayText,
                        ),
                      ),
                    ],
                  ),
                  3.h.height,
                  Text(
                    message,
                    maxLines: 3,
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
            if (unread) ...[
              12.w.width,
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
                ),
              ),
            ] else
              16.w.width,
          ],
        ),
      ),
    );
  }
}
