import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

import 'app_icon.dart';

/// One row of a settings card or an option sheet: a tinted tile, a bold title with an optional gray hint, and a
/// trailing widget — a chevron by default for a tappable row. Every row but the [first] draws a hairline above.
class SettingRow extends StatelessWidget {
  /// SVG asset of the tile glyph.
  final String icon;

  /// Color family of the tile and, for the error tone, of the title too (the sign-out row).
  final StatusTone tone;

  /// Main text of the row.
  final String title;

  /// Gray second line (the current value, a hint); omitted when null.
  final String? subtitle;

  /// Widget drawn at the end instead of the chevron (a switch, a check mark).
  final Widget? trailing;

  /// Tap handler; a tappable row without [trailing] shows a chevron.
  final VoidCallback? onTap;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Horizontal padding of the row (16 inside a card, 0 inside a sheet that already pads).
  final double inset;

  /// False to draw the title in medium weight (unselected choices of an option sheet).
  final bool bold;

  /// Builds the row.
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.tone = StatusTone.primary,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.first = false,
    this.inset = 16,
    this.bold = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 60.h),
        padding: EdgeInsets.symmetric(horizontal: inset.w),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line, width: 0.5)),
        ),
        child: Row(
          children: [
            AppIcon.tile(icon, tone: tone, size: 38),
            14.w.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(
                      fontSize: 16.sp,
                      fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                      color: tone == StatusTone.error ? theme.red : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    1.h.height,
                    Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              8.w.width,
              trailing!,
            ] else if (onTap != null && tone != StatusTone.error)
              AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
