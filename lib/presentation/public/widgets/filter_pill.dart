import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Rounded filter/choice chip. Selected pills invert to the text color; an
/// optional [icon] or [leading] avatar sits before the label.
class FilterPill extends StatelessWidget {
  /// Text of the pill.
  final String label;

  /// Whether the pill is the active choice.
  final bool selected;

  /// Tap handler.
  final VoidCallback? onTap;

  /// SVG asset (an `AppIcons` constant) drawn before the label.
  final String? icon;

  /// Custom leading widget (an avatar); wins over [icon].
  final Widget? leading;

  /// Builds the pill.
  const FilterPill({super.key, required this.label, this.selected = false, this.onTap, this.icon, this.leading});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? theme.background : theme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36.h,
        padding: EdgeInsets.fromLTRB(leading != null ? 6.w : 14.w, 0, 14.w, 0),
        decoration: BoxDecoration(
          color: selected ? theme.text : theme.cardColor,
          borderRadius: 18.circular,
          border: Border.all(color: selected ? theme.text : theme.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              6.w.width,
            ] else if (icon != null) ...[
              AppIcon(icon!, size: 16.sp, color: fg),
              6.w.width,
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textStyle.copyWith(fontSize: 14.sp, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
