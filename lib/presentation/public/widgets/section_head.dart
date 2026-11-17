import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Section heading with an optional green action link on the right ("Hammasi", "Reyting").
class SectionHead extends StatelessWidget {
  /// Heading text.
  final String title;

  /// Label of the action link; omitted when null.
  final String? action;

  /// Tap handler of the action link.
  final VoidCallback? onAction;

  /// Lighter suffix written after the title ("· shu hafta"); omitted when null.
  final String? note;

  /// True to draw a small chevron after the action link.
  final bool chevron;

  /// Builds the heading.
  const SectionHead(this.title, {super.key, this.action, this.onAction, this.note, this.chevron = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              children: [
                if (note != null)
                  TextSpan(
                    text: ' $note',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w400, color: theme.textSecondary),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: theme.textStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.primary),
                ),
                if (chevron) ...[2.w.width, AppIcon(AppIcons.right, size: 16.sp, color: theme.primary)],
              ],
            ),
          ),
      ],
    );
  }
}
