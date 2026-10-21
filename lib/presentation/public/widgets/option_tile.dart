import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// One row of a settings/list card: leading widget, title with optional
/// subtitle, trailing widget (or a chevron when tappable). Put several inside
/// a `CardWidget(padding: EdgeInsets.zero)`; every row but the [first] draws a
/// hairline above itself.
class OptionTile extends StatelessWidget {
  /// Main text of the row.
  final String title;

  /// Dimmer second line under [title].
  final String? subtitle;

  /// Color of [subtitle]; defaults to the hint gray.
  final Color? subtitleColor;

  /// Widget drawn before the text (avatar, tile, icon).
  final Widget? leading;

  /// Widget drawn at the end; replaces the chevron.
  final Widget? trailing;

  /// Tap handler; a tappable row shows a chevron when [trailing] is null.
  final VoidCallback? onTap;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Builds the row.
  const OptionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 56.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, 12.w.width],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.cardSubtitle.copyWith(color: subtitleColor),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              8.w.width,
              trailing!,
            ] else if (onTap != null)
              AppIcon(AppIcons.right, color: theme.grayText),
          ],
        ),
      ),
    );
  }
}
