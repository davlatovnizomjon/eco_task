import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/stats_period.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';

/// Top card of a statistics screen: the caption, the big headline number with its change chip, a hint line, an
/// optional pair of tiles and any extra [child] (a chart, a stacked bar).
class StatsHeadCard extends StatelessWidget {
  /// Caption above the number ("Daromad", "Jami vazifalar").
  final String caption;

  /// The headline number, already formatted.
  final String value;

  /// Change against the previous period; null hides the chip. A percent unless [deltaIsCount].
  final num? delta;

  /// True when [delta] is a head count ("+2") instead of a percent.
  final bool deltaIsCount;

  /// Window length, for the "compared with last …" hint.
  final StatsPeriod period;

  /// Text under the number instead of the "compared with" hint; omitted when null.
  final String? note;

  /// Two tiles under the number, as `(caption, value)` pairs; omitted when empty.
  final List<(String, String)> tiles;

  /// Extra content under the tiles.
  final Widget? child;

  /// Builds the card.
  const StatsHeadCard({
    super.key,
    required this.caption,
    required this.value,
    required this.period,
    this.delta,
    this.deltaIsCount = false,
    this.note,
    this.tiles = const [],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    /// True for a drop, which is drawn in red with a down arrow.
    final down = (delta ?? 0) < 0;

    /// Color of the change chip.
    final tone = down ? theme.red : theme.primary;
    return CardWidget(
      padding: EdgeInsets.all(16.w),
      decoration: theme.panelDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: theme.cardSubtitle),
          4.h.height,
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(
                    fontSize: 30.sp,
                    height: 36 / 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (delta != null) ...[
                10.w.width,
                Container(
                  height: 26.h,
                  padding: EdgeInsets.fromLTRB(8.w, 0, 10.w, 0),
                  decoration: BoxDecoration(color: tone.withValues(alpha: 0.14), borderRadius: 13.circular),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(down ? AppIcons.down : AppIcons.up, size: 14.sp, color: tone),
                      4.w.width,
                      Text(
                        deltaIsCount ? '${delta!.abs()}' : '${delta!.abs()}%',
                        style: theme.badgeText.copyWith(color: tone),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (delta != null || note != null) ...[
            4.h.height,
            Text(note ?? period.versus, style: theme.cardSubtitle.copyWith(fontSize: 12.sp)),
          ],
          if (tiles.isNotEmpty) ...[
            14.h.height,
            Row(
              children: [
                for (final (i, t) in tiles.indexed) ...[
                  if (i > 0) 10.w.width,
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(color: theme.cardColorLight, borderRadius: 14.circular),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
                          2.h.height,
                          Text(
                            t.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textStyle.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (child != null) ...[14.h.height, child!],
        ],
      ),
    );
  }
}
