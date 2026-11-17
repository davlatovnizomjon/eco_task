import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/chat_message.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../widgets/attachment_view.dart';
import '../widgets/reply_quote.dart';

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

  /// Called on a long press; opens the actions sheet. Null disables it (pending and deleted messages).
  final VoidCallback? onLongPress;

  /// Id of the signed-in person, to tell which reactions are theirs.
  final String meId;

  /// Called with the emoji of a tapped reaction chip.
  final ValueChanged<String>? onReact;

  /// Builds the bubble.
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.showAuthor = false,
    this.read = false,
    this.onRetry,
    this.onLongPress,
    this.onReact,
    this.meId = '',
  });

  @override
  Widget build(BuildContext context) {
    final failed = message.delivery == ChatDelivery.failed;
    final fg = mine ? theme.onPrimary : theme.text;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: 0.84.sw - 40.w),
      padding: EdgeInsets.fromLTRB(11.w, 7.h, 11.w, 6.h),
      decoration: BoxDecoration(
        color: mine ? theme.primary : theme.cardColor,
        border: mine ? null : Border.all(color: theme.line),
        borderRadius: BorderRadius.only(
          topLeft: 18.circularRadius,
          topRight: 18.circularRadius,
          bottomLeft: (mine ? 18 : 6).circularRadius,
          bottomRight: (mine ? 6 : 18).circularRadius,
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
          if (message.replyTo != null && !message.deleted) ...[
            ReplyQuote(reply: message.replyTo!, color: mine ? theme.onPrimary : theme.primary),
            6.h.height,
          ],
          if (message.attachment != null && !message.deleted) ...[
            AttachmentView(file: message.attachment!, color: fg),
            if (message.body.isNotEmpty) 6.h.height,
          ],
          if (message.deleted || message.body.isNotEmpty)
            Text(
              message.deleted ? TrWords.ch2Deleted.tr() : message.body,
              style: theme.textStyle.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.35,
                fontStyle: message.deleted ? FontStyle.italic : null,
                color: message.deleted ? fg.withValues(alpha: 0.7) : fg,
              ),
            ),
          if (message.reactions.isNotEmpty && !message.deleted) ...[
            6.h.height,
            Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: [
                for (final r in message.reactions)
                  GestureDetector(
                    onTap: onReact == null ? null : () => onReact!(r.emoji),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: r.userIds.contains(meId)
                            ? (mine ? theme.onPrimary.withValues(alpha: 0.28) : theme.primaryTint)
                            : (mine ? theme.onPrimary.withValues(alpha: 0.14) : theme.cardColorLight),
                        borderRadius: 11.circular,
                        border: r.userIds.contains(meId) ? Border.all(color: mine ? fg : theme.primary) : null,
                      ),
                      child: Text(
                        '${r.emoji} ${r.userIds.length}',
                        style: theme.textStyle.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: fg),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          4.h.height,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.editedAt != null && !message.deleted) ...[
                Text(
                  TrWords.ch2Edited.tr(),
                  style: theme.cardSubtitle.copyWith(fontSize: 11.sp, color: fg.withValues(alpha: 0.7)),
                ),
                4.w.width,
              ],
              Text(
                DateFormatter.time(message.at),
                style: theme.cardSubtitle.copyWith(fontSize: 11.sp, color: fg.withValues(alpha: 0.7)),
              ),
              if (mine) ...[
                4.w.width,
                switch (message.delivery) {
                  ChatDelivery.sending => AppIcon(AppIcons.clock, size: 12.sp, color: fg.withValues(alpha: 0.7)),
                  ChatDelivery.failed => AppIcon(AppIcons.alert, size: 12.sp, color: theme.red),
                  ChatDelivery.sent => AppIcon(read ? AppIcons.checks : AppIcons.check, size: 12.sp, color: fg),
                },
              ],
            ],
          ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine && showAuthor) ...[UserAvatar(message.sender, size: 28.w), 6.w.width],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              behavior: HitTestBehavior.opaque,
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
          ),
        ],
      ),
    );
  }
}

/// Centered caption between messages of different days ("Bugun", "Kecha", "8-oktabr").
class DayPill extends StatelessWidget {
  /// A moment of the day being captioned.
  final DateTime day;

  /// Builds the caption.
  const DayPill(this.day, {super.key});

  @override
  Widget build(BuildContext context) {
    final diff = DateFormatter.daysTo(day);
    final label = diff == 0
        ? TrWords.cToday.tr()
        : diff == -1
        ? TrWords.cYesterday.tr()
        : DateFormatter.day(day);
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(color: theme.cardColorLight.withValues(alpha: 0.9), borderRadius: 10.circular),
      child: Text(
        label,
        style: theme.textStyle.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600, color: theme.textSecondary),
      ),
    );
  }
}
