import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// The strip under the room's bar that shows the pinned message: a pin glyph, the green caption and the text on one
/// line, and a close "x" that clears the pin.
class PinnedBanner extends StatelessWidget {
  /// Text of the pinned message.
  final String text;

  /// Called when the "x" is tapped.
  final VoidCallback onClear;

  /// Builds the strip.
  const PinnedBanner({super.key, required this.text, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.only(left: 14.w, right: 4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(width: 3.w, height: 30.h, color: theme.primary),
          10.w.width,
          AppIcon(AppIcons.pin, size: 18.sp, color: theme.primary),
          10.w.width,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TrWords.ch2Pinned.tr(),
                  style: theme.textStyle.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700, color: theme.primary),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle.copyWith(fontSize: 13.sp, color: theme.text),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: AppIcon(AppIcons.x, size: 18.sp, color: theme.grayText),
          ),
        ],
      ),
    );
  }
}
