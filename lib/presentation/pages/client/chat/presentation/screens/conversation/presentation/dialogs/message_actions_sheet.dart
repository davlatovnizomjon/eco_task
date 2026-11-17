import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// What a long press on a message can do; the room turns each into an event.
enum MessageAction {
  /// Answer the message ("Javob berish").
  reply,

  /// Put an emoji on the message.
  react,

  /// Copy the text to the clipboard.
  copy,

  /// Edit the text (own messages).
  edit,

  /// Pin or unpin the message.
  pin,

  /// Delete the message (own, or any for staff).
  delete,
}

/// The pick of [MessageActionsSheet]: an action, plus the emoji for [MessageAction.react].
typedef MessageChoice = ({MessageAction action, String? emoji});

/// Bottom sheet opened by a long press on a message: a row of quick emojis (the one already chosen is highlighted)
/// above the actions copy, edit, pin / unpin and delete. Resolves to the choice, or null when dismissed.
class MessageActionsSheet extends StatelessWidget {
  /// Text of the message, shown as a one-line preview.
  final String preview;

  /// Emoji the caller already put on the message, if any.
  final String? mine;

  /// True when the caller wrote the message (enables edit).
  final bool canEdit;

  /// True when the caller may delete it.
  final bool canDelete;

  /// True when this very message is the pinned one (the action reads "unpin").
  final bool pinned;

  /// Builds the sheet.
  const MessageActionsSheet({
    super.key,
    required this.preview,
    required this.mine,
    required this.canEdit,
    required this.canDelete,
    required this.pinned,
  });

  /// The quick reactions offered.
  static const emojis = ['👍', '❤️', '😂', '😊', '🙏', '👏', '🔥', '✅', '🎉', '😢', '😮'];

  /// Opens the sheet; copying is handled here (clipboard) and still reported as the choice.
  static Future<MessageChoice?> show(
    BuildContext context, {
    required String preview,
    required String? mine,
    required bool canEdit,
    required bool canDelete,
    required bool pinned,
  }) async {
    /// What the person picked; null when the sheet was dismissed.
    final choice = await showBottomDialog<MessageChoice>(
      MessageActionsSheet(preview: preview, mine: mine, canEdit: canEdit, canDelete: canDelete, pinned: pinned),
      context,
    );
    if (choice?.action == MessageAction.copy) await Clipboard.setData(ClipboardData(text: preview));
    return choice;
  }

  @override
  Widget build(BuildContext context) {
    /// One action row: glyph, label, red when destructive.
    Widget row(MessageAction action, String icon, String label, {bool danger = false}) => InkWell(
      onTap: () => Navigator.pop(context, (action: action, emoji: null) as MessageChoice),
      child: Container(
        height: 48.h,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.line, width: 0.5)),
        ),
        child: Row(
          children: [
            AppIcon(icon, size: 20.sp, color: danger ? theme.red : theme.text),
            14.w.width,
            Text(
              label,
              style: theme.textStyle.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: danger ? theme.red : theme.text,
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final e in emojis)
                GestureDetector(
                  onTap: () => Navigator.pop(context, (action: MessageAction.react, emoji: e) as MessageChoice),
                  child: Container(
                    width: 44.w,
                    margin: EdgeInsets.only(right: 6.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mine == e ? theme.primaryTint : theme.cardColorLight,
                      shape: BoxShape.circle,
                      border: mine == e ? Border.all(color: theme.primary) : null,
                    ),
                    child: Text(e, style: TextStyle(fontSize: 22.sp)),
                  ),
                ),
            ],
          ),
        ),
        12.h.height,
        Text(
          preview,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.cardSubtitle.copyWith(fontSize: 14.sp),
        ),
        10.h.height,
        row(MessageAction.reply, AppIcons.reply, TrWords.ch2Reply.tr()),
        row(MessageAction.copy, AppIcons.copy, TrWords.ch2Copy.tr()),
        if (canEdit) row(MessageAction.edit, AppIcons.edit, TrWords.ch2Edit.tr()),
        row(MessageAction.pin, AppIcons.pin, (pinned ? TrWords.ch2Unpin : TrWords.ch2Pin).tr()),
        if (canDelete) row(MessageAction.delete, AppIcons.trash, TrWords.ch2Delete.tr(), danger: true),
      ],
    );
  }
}
