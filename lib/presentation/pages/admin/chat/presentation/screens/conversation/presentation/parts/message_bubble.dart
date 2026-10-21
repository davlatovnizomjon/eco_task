import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/chat_message.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// One chat bubble. The signed-in user's messages sit on the right in the
/// brand color with a delivery mark; others' sit on the left with the author
/// shown when [showAuthor] is set (group and task chats).
class MessageBubble extends StatelessWidget {
  /// Message to show.
  final ChatMessage message;

  /// True when the signed-in user wrote it.
  final bool mine;

  /// True when the author's avatar and name are shown (group and task chats).
  final bool showAuthor;

  /// True when somebody else has read this message (shown as a second tick).
  final bool read;

  /// Sends a failed message again.
  final VoidCallback? onRetry;

  /// Builds the bubble.
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.showAuthor = false,
    this.read = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failed = message.delivery == ChatDelivery.failed;
    final fg = mine ? theme.onPrimary : theme.text;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: 270.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: mine ? theme.primary : theme.cardColor,
        border: mine ? null : Border.all(color: theme.line),
        borderRadius: BorderRadius.only(
          topLeft: 14.circularRadius,
          topRight: 14.circularRadius,
          bottomLeft: (mine ? 14 : 4).circularRadius,
          bottomRight: (mine ? 4 : 14).circularRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAuthor && !mine && message.sender.name.isNotEmpty) ...[
            Text(
              message.sender.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.fieldLabel.copyWith(color: theme.primary),
            ),
            2.h.height,
          ],
          Text(
            message.body,
            style: theme.textStyle.copyWith(fontWeight: FontWeight.w400, height: 1.35, color: fg),
          ),
          4.h.height,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatter.time(message.at),
                style: theme.cardSubtitle.copyWith(fontSize: 11.sp, color: fg.withValues(alpha: 0.7)),
              ),
              if (mine) ...[
                4.w.width,
                switch (message.delivery) {
                  ChatDelivery.sending => AppIcon(AppIcons.clock, size: 12.sp, color: fg.withValues(alpha: 0.7)),
                  ChatDelivery.failed => AppIcon(AppIcons.alert, size: 12.sp, color: theme.red),
                  ChatDelivery.sent => AppIcon(read ? AppIcons.checkc : AppIcons.check, size: 12.sp, color: fg),
                },
              ],
            ],
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine && showAuthor) ...[UserAvatar(message.sender, size: 28.w), 6.w.width],
          Flexible(
            child: failed
                ? GestureDetector(
                    onTap: onRetry,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        bubble,
                        2.h.height,
                        Text(TrWords.chatFailed.tr(), style: theme.cardSubtitle.copyWith(color: theme.red)),
                      ],
                    ),
                  )
                : bubble,
          ),
        ],
      ),
    );
  }
}
