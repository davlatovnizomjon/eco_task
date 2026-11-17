import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Flat list row (leading marker, two text lines, trailing value, chevron) separated from its neighbours by an
/// inset hairline. The standard row of the task, employee, client and archive lists.
class ListRow extends StatelessWidget {
  /// Leading marker (avatar, [ToneCircle]).
  final Widget leading;

  /// Primary line.
  final String title;

  /// Secondary line; omitted when null.
  final String? subtitle;

  /// Color of the secondary line; defaults to the secondary text color.
  final Color? subtitleColor;

  /// Weight of the secondary line.
  final FontWeight? subtitleWeight;

  /// Trailing block (due date, count, chip); omitted when null.
  final Widget? trailing;

  /// Tap handler; the chevron shows only when set and [chevron] is true.
  final VoidCallback? onTap;

  /// Whether the right chevron is drawn.
  final bool chevron;

  /// True for the first row of a group (no top hairline).
  final bool first;

  /// Left inset of the hairline, so it starts under the text.
  final double dividerInset;

  /// Font size of the title (16 on full lists, 15 inside dashboard cards).
  final double titleSize;

  /// Builds the row.
  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.subtitleWeight,
    this.trailing,
    this.onTap,
    this.chevron = true,
    this.first = false,
    this.dividerInset = 46,
    this.titleSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          if (!first)
            Positioned(
              top: 0,
              left: dividerInset.w,
              right: 0,
              child: Container(height: 0.5, color: theme.line),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                leading,
                12.w.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyle.copyWith(
                          fontSize: titleSize.sp,
                          height: 21 / titleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        3.h.height,
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(
                            fontSize: 13.sp,
                            fontWeight: subtitleWeight ?? FontWeight.w400,
                            color: subtitleColor ?? theme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[8.w.width, trailing!],
                if (chevron && onTap != null) ...[
                  6.w.width,
                  AppIcon(AppIcons.right, size: 16.sp, color: theme.grayText.withValues(alpha: 0.6)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Upper-case group caption above a run of [ListRow]s ("TODAY", "OVERDUE").
class ListGroupTitle extends StatelessWidget {
  /// Caption text (drawn upper-case).
  final String text;

  /// Tints the caption amber for the overdue group.
  final bool warn;

  /// Builds the caption.
  const ListGroupTitle(this.text, {super.key, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(2.w, 16.h, 2.w, 4.h),
      child: Text(
        text.toUpperCase(),
        style: theme.textStyle.copyWith(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: warn ? theme.warn : theme.textSecondary,
        ),
      ),
    );
  }
}
