import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';

/// Placeholder card of an empty dashboard block ("no own tasks", "no rating yet", "nothing due today"): a tinted
/// tile, a title with a hint and, when [onAdd] is given, a small "+" button.
class DashboardHintCard extends StatelessWidget {
  /// SVG asset of the tile glyph.
  final String icon;

  /// Color family of the tile.
  final StatusTone tone;

  /// Bold first line.
  final String title;

  /// Gray second line.
  final String subtitle;

  /// Tap handler of the "+" button; the button is omitted when null.
  final VoidCallback? onAdd;

  /// Builds the card.
  const DashboardHintCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = StatusTone.primary,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      padding: EdgeInsets.all(14.w),
      decoration: theme.panelDecor,
      child: Row(
        children: [
          AppIcon.tile(icon, tone: tone, size: 44),
          12.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(fontWeight: FontWeight.w600),
                ),
                2.h.height,
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
              ],
            ),
          ),
          if (onAdd != null) ...[
            12.w.width,
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 36.w,
                height: 36.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.primaryTint, borderRadius: 12.circular),
                child: AppIcon(AppIcons.plus, size: 20.sp, color: theme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
