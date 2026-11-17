import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

import 'app_icon.dart';

/// Panel card with a tinted icon tile, a big number, a caption and a chevron — the dashboard shortcuts to the
/// employees and clients lists.
class LinkStatCard extends StatelessWidget {
  /// SVG asset of the tile glyph.
  final String icon;

  /// Color family of the tile.
  final StatusTone tone;

  /// Big number.
  final String value;

  /// Caption under the number.
  final String label;

  /// Tap handler.
  final VoidCallback onTap;

  /// Builds the card.
  const LinkStatCard({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                    value,
                    style: theme.textStyle.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w700),
                  ),
                  Text(label, style: theme.cardSubtitle),
                ],
              ),
            ),
            AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText),
          ],
        ),
      ),
    );
  }
}
