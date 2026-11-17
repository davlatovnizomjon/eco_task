import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// The wide green call-to-action button (48 px, 12 px corners): the [text], optionally followed by a [trailingIcon].
/// While [isLoading] it shows a spinner before [loadingText] (or [text] when none is given), drops the icon and ignores
/// taps. A null [onPressed] disables the button: a washed-out green fill with a soft label and no splash. Pressing (or hovering with a pointer) shows the standard `InkWell` splash and highlight.
class PrimaryButton extends StatelessWidget {
  /// Label of the button.
  final String text;

  /// Tap handler; ignored while [isLoading]; null disables the button.
  final VoidCallback? onPressed;

  /// Label shown instead of [text] while [isLoading]; [text] stays when null.
  final String? loadingText;

  /// Whether the action is running: spinner, [loadingText] and no taps.
  final bool isLoading;

  /// SVG asset (an `AppIcons` constant) drawn after the label; omitted when null.
  final String? trailingIcon;

  /// Builds the button.
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loadingText,
    this.isLoading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Loading keeps the full colour; only a missing handler looks disabled.
    final disabled = onPressed == null && !isLoading;
    final labelColor = disabled ? theme.onPrimary.withValues(alpha: theme.dark ? 0.6 : 0.92) : theme.onPrimary;
    // The Material carries the fill, so the InkWell's splash and hover/press highlight are painted on top of it.
    return Material(
      color: disabled ? Color.lerp(theme.background, theme.primary, 0.4) : theme.primary,
      borderRadius: 12.circular,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        child: Container(
          height: 48.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.onPrimary.withValues(alpha: 0.85)),
                ),
                8.w.width,
              ],
              Text(
                isLoading ? (loadingText ?? text) : text,
                style: theme.textStyle.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w600, color: labelColor),
              ),
              if (!isLoading && trailingIcon != null) ...[
                8.w.width,
                AppIcon(trailingIcon!, size: 18.sp, color: labelColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
