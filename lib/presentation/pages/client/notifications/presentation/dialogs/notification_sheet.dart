import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';

/// Bottom sheet with one notification in full: the title, when it arrived and the whole message, plus an "open"
/// button when the entry points at a screen.
class NotificationSheet extends StatelessWidget {
  /// Bold title.
  final String title;

  /// Relative time written under the title.
  final String time;

  /// Whole message.
  final String message;

  /// Opens the screen the entry is about; null hides the button.
  final VoidCallback? onOpen;

  /// Builds the sheet.
  const NotificationSheet({super.key, required this.title, required this.time, required this.message, this.onOpen});

  /// Opens the sheet for an entry.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String time,
    required String message,
    VoidCallback? onOpen,
  }) => showBottomDialog<void>(NotificationSheet(title: title, time: time, message: message, onOpen: onOpen), context);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
        ),
        6.h.height,
        Text(time, style: theme.cardSubtitle.copyWith(fontSize: 14.sp)),
        10.h.height,
        Text(
          message,
          style: theme.textStyle.copyWith(height: 22 / 15, fontWeight: FontWeight.w400),
        ),
        if (onOpen != null) ...[
          18.h.height,
          Btn(
            text: TrWords.cOpen.tr(),
            height: 52.h,
            onPressed: () {
              Navigator.pop(context);
              onOpen!();
            },
          ),
        ],
      ],
    );
  }
}
