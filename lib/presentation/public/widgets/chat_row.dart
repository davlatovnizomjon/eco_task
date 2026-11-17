import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Conversation row of the chat list: 48 px avatar (optionally with an online dot), name + time, last message
/// preview and an unread counter.
class ChatRow extends StatelessWidget {
  /// Round avatar or group tile.
  final Widget avatar;

  /// Whether the green presence dot is drawn on the avatar.
  final bool online;

  /// Conversation name.
  final String name;

  /// Small chip after the name (client badge); omitted when null.
  final Widget? badge;

  /// Time of the last message.
  final String time;

  /// Preview of the last message.
  final String message;

  /// Unread messages; hidden when 0.
  final int unread;

  /// Shows [message] as a green italic "typing" hint.
  final bool typing;

  /// Leading glyph before the preview (read receipt); omitted when null.
  final Widget? receipt;

  /// Tap handler.
  final VoidCallback? onTap;

  /// True for the first row of a list (no top hairline).
  final bool first;

  /// Builds the row.
  const ChatRow({
    super.key,
    required this.avatar,
    this.online = false,
    required this.name,
    this.badge,
    required this.time,
    required this.message,
    this.unread = 0,
    this.typing = false,
    this.receipt,
    this.onTap,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    final fresh = unread > 0;
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          if (!first)
            Positioned(
              top: 0,
              left: 62.w,
              right: 0,
              child: Container(height: 1, color: theme.line),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 11.h),
            child: Row(
              children: [
                SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      avatar,
                      if (online)
                        Positioned(
                          right: 1,
                          bottom: 1,
                          child: Container(
                            width: 12.w,
                            height: 12.w,
                            decoration: BoxDecoration(
                              color: theme.online,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.background, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                12.w.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textStyle.copyWith(fontWeight: fresh ? FontWeight.w700 : FontWeight.w600),
                            ),
                          ),
                          if (badge != null) ...[6.w.width, badge!],
                          const Spacer(),
                          Text(
                            time,
                            style: theme.textStyle.copyWith(
                              fontSize: 12.sp,
                              fontWeight: fresh ? FontWeight.w600 : FontWeight.w400,
                              color: fresh ? theme.primary : theme.grayText,
                            ),
                          ),
                        ],
                      ),
                      3.h.height,
                      Row(
                        children: [
                          if (receipt != null) ...[receipt!, 4.w.width],
                          Expanded(
                            child: Text(
                              message,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textStyle.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                fontStyle: typing ? FontStyle.italic : FontStyle.normal,
                                color: typing ? theme.primary : theme.textSecondary,
                              ),
                            ),
                          ),
                          if (fresh) ...[
                            8.w.width,
                            Container(
                              constraints: BoxConstraints(minWidth: 20.w),
                              height: 20.w,
                              padding: EdgeInsets.symmetric(horizontal: 6.w),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: theme.primary, borderRadius: 10.circular),
                              child: Text(
                                '$unread',
                                style: theme.textStyle.copyWith(
                                  fontSize: 11.sp,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  color: theme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
