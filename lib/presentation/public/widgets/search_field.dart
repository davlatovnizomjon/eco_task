import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Search box of the list screens: a 46 px rounded field with a leading magnifier. Typing is live
/// ([onChanged]); with [onTap] and no [controller] it acts as a button that opens a search screen.
class SearchField extends StatelessWidget {
  /// Placeholder text.
  final String hint;

  /// Text controller; null makes the field read-only.
  final TextEditingController? controller;

  /// Called on every edit.
  final ValueChanged<String>? onChanged;

  /// Called when a read-only field is tapped.
  final VoidCallback? onTap;

  /// Builds the field.
  const SearchField({super.key, required this.hint, this.controller, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hintStyle = theme.textStyle.copyWith(
      fontSize: 16.sp,
      fontWeight: FontWeight.w400,
      color: theme.textSecondary,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: 13.circular,
          border: Border.all(color: theme.line),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.search, size: 20.sp, color: theme.textSecondary),
            10.w.width,
            Expanded(
              child: controller == null
                  ? Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: hintStyle)
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      cursorColor: theme.primary,
                      style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: hintStyle,
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 46 px square button beside a [SearchField] (filter, sort); filled green while [active].
class SquareIconButton extends StatelessWidget {
  /// SVG asset of the glyph.
  final String icon;

  /// Tap handler.
  final VoidCallback onTap;

  /// Whether a filter is applied: fills the button and shows a red dot.
  final bool active;

  /// Builds the button.
  const SquareIconButton({super.key, required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46.w,
        height: 46.w,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: 13.circular,
          border: Border.all(color: theme.line),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AppIcon(icon, size: 22.sp, color: theme.primary),
            if (active)
              Positioned(
                top: -5.w,
                right: -5.w,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: theme.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.background, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
