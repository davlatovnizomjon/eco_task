import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

import 'app_icon.dart';

/// Colored strip with a glyph and a sentence — validation summaries, offline
/// notices, hints. The tone picks background, glyph and text emphasis.
class NoticeBanner extends StatelessWidget {
  /// The sentence shown in the strip.
  final String text;

  /// Color family of the strip.
  final StatusTone tone;

  /// SVG asset (an `AppIcons` constant) at the start; defaults to the info glyph.
  final String icon;

  /// Optional widget under the text (e.g. a link button).
  final Widget? action;

  /// Builds the banner.
  const NoticeBanner({
    super.key,
    required this.text,
    this.tone = StatusTone.warn,
    this.icon = AppIcons.info,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: tone.bgColor, borderRadius: 12.circular),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: tone.color),
          10.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle.copyWith(color: theme.text, height: 1.35),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
