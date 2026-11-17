import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// One line of a statistics card: a tinted tile, a title with a gray hint and a bold value at the right. Rows sit in
/// a `CardWidget(horizontal 16, vertical 2–4)`; every row but the [first] draws a hairline above itself.
class StatsFactRow extends StatelessWidget {
  /// SVG asset of the tile glyph.
  final String icon;

  /// Color family of the tile.
  final StatusTone tone;

  /// Bold first line.
  final String title;

  /// Gray second line.
  final String subtitle;

  /// Value at the right edge.
  final String value;

  /// True to draw [value] in the tile's color (an alarming count).
  final bool tinted;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Builds the row.
  const StatsFactRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.tone = StatusTone.primary,
    this.tinted = false,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: theme.line, width: 0.5)),
      ),
      child: Row(
        children: [
          AppIcon.tile(icon, tone: tone, size: 36),
          12.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
                ),
              ],
            ),
          ),
          8.w.width,
          Text(
            value,
            style: theme.textStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: tinted ? tone.color : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
