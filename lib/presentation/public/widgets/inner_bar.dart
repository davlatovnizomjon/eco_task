import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Top bar of a pushed screen: a primary-colored back chevron on the left, a centered title (or custom
/// [center] block) and trailing actions, closed by a hairline.
class InnerBar extends StatelessWidget {
  /// Centered title; ignored when [center] is set.
  final String? title;

  /// Custom centered block (chat header); replaces [title].
  final Widget? center;

  /// Trailing action buttons (usually `HeaderAction`s).
  final List<Widget> actions;

  /// Overrides the back handler; defaults to popping the route.
  final VoidCallback? onBack;

  /// Hides the back chevron (sheet-like roots).
  final bool showBack;

  /// Builds the bar.
  const InnerBar({super.key, this.title, this.center, this.actions = const [], this.onBack, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 4.w, right: 8.w),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.92),
        border: Border(bottom: BorderSide(color: theme.line, width: 0.5)),
      ),
      child: SizedBox(
        height: 52.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 52.w),
              child:
                  center ??
                  Text(
                    title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                  ),
            ),
            if (showBack)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44.w,
                    height: 44.w,
                    child: Center(
                      child: AppIcon(AppIcons.left, size: 28.sp, color: theme.primary),
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ],
        ),
      ),
    );
  }
}
