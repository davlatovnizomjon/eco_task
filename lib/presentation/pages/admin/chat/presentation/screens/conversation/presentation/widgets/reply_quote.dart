import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/chat_message.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';

/// The quoted card of an answered message: a colored bar, the author's name and a one-line preview. [color] is the
/// accent (white on the user's own bubble, the brand color elsewhere); [onClose] adds an "x" for the reply bar.
class ReplyQuote extends StatelessWidget {
  /// The quoted message.
  final ChatReply reply;

  /// Color of the bar, the name and the preview.
  final Color color;

  /// Called by the "x"; null hides it.
  final VoidCallback? onClose;

  /// Builds the card.
  const ReplyQuote({super.key, required this.reply, required this.color, this.onClose});

  /// What the card says in place of text: the attachment kind, the deleted note or the text itself.
  String get _preview {
    if (reply.deleted) return TrWords.ch2Deleted.tr();
    if (reply.body.isNotEmpty) return reply.body;
    return switch (reply.attachmentKind) {
      FileKind.image => TrWords.flPhoto.tr(),
      FileKind.audio => TrWords.flVoice.tr(),
      FileKind.video => TrWords.flCircle.tr(),
      _ => TrWords.flDocument.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 3.w,
            decoration: BoxDecoration(color: color, borderRadius: 2.circular),
          ),
          8.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  reply.senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.fieldLabel.copyWith(color: color),
                ),
                Text(
                  _preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle.copyWith(fontSize: 13.sp, color: color.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Icon(Icons.close_rounded, size: 18.sp, color: theme.grayText),
              ),
            ),
        ],
      ),
    );
  }
}
