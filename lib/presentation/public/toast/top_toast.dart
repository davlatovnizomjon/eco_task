import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// Toast pinned to the top of a screen: a round tinted icon, a bold title and a message. It has no close button: it hides
/// itself (shown through `showTopToast` in `toast_helpers.dart`). Its border takes the tone's color for warnings, errors and success.
class TopToast extends StatelessWidget {
  /// SVG asset of the glyph in the round marker.
  final String icon;

  /// Color family of the marker and the border.
  final StatusTone tone;

  /// Bold first line.
  final String title;

  /// Explanation under [title].
  final String message;

  /// Builds the toast.
  const TopToast({super.key, required this.icon, required this.tone, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: 16.circular,
        border: Border.all(color: Color.alphaBlend(tone.color.withValues(alpha: 0.35), theme.line)),
        boxShadow: theme.toastShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tone.bgColor, shape: BoxShape.circle),
            child: AppIcon(icon, size: 20.sp, color: tone.color),
          ),
          12.w.width,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textStyle.copyWith(
                      fontSize: 15.sp,
                      height: 20 / 15,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(650)],
                    ),
                  ),
                  2.h.height,
                  Text(
                    message,
                    style: theme.textStyle.copyWith(
                      fontSize: 13.sp,
                      height: 18 / 13,
                      fontWeight: FontWeight.w400,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
