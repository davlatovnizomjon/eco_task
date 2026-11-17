import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// A 40 px icon button in the primary color used in [LargeTitleHeader] and [InnerBar], with an optional
/// red unread badge.
class HeaderAction extends StatelessWidget {
  /// SVG asset of the glyph.
  final String icon;

  /// Tap handler.
  final VoidCallback onTap;

  /// Number shown in the red badge; hidden when 0.
  final int badge;

  /// Glyph color; defaults to the brand color.
  final Color? color;

  /// Builds the action button.
  const HeaderAction({super.key, required this.icon, required this.onTap, this.badge = 0, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40.w,
        height: 40.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppIcon(icon, size: 24.sp, color: color ?? theme.primary),
            if (badge > 0)
              Positioned(
                top: 3.h,
                right: 0,
                child: CountBadge(badge, ring: theme.cardColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small red pill with a count, used on icons and tab bar items.
class CountBadge extends StatelessWidget {
  /// Number to show; values above 99 render as `99+`.
  final int count;

  /// Color of the ring that separates the badge from the icon under it.
  final Color ring;

  /// Builds the badge.
  const CountBadge(this.count, {super.key, required this.ring});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 18.w),
      height: 18.w,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.red,
        borderRadius: 9.circular,
        border: Border.all(color: ring, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textStyle.copyWith(
          fontSize: 10.5.sp,
          height: 1,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}
