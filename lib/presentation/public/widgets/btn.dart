import 'package:flutter/material.dart';
import 'package:flutter_bounce/flutter_bounce.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// The app's only button. Every call site uses this widget or one of its
/// factory variants — a hand-rolled `Container`/`ElevatedButton` is banned.
class Btn extends StatelessWidget {
  /// Label rendered in the middle of the button.
  final String text;

  /// Tap handler; a null handler renders the button dimmed and inert.
  final VoidCallback? onPressed;

  /// Full surface override; defaults to the filled brand surface.
  final BoxDecoration? decoration;

  /// Label style override; defaults to the on-primary label.
  final TextStyle? textStyle;

  /// Space around the button.
  final EdgeInsets margin;

  /// Space inside the button, around its row of children.
  final EdgeInsets? padding;

  /// While true the label is replaced by a spinner and taps are ignored.
  final bool isLoading;

  /// SVG asset (an `AppIcons` constant) drawn before the label.
  final String? icon;

  /// Fixed height; defaults to the standard 50.h control height.
  final double? height;

  /// How many lines [text] may wrap to before it is ellipsized.
  final int maxLines;

  /// Builds the default filled brand button.
  const Btn({
    super.key,
    required this.text,
    this.onPressed,
    this.decoration,
    this.textStyle,
    this.margin = EdgeInsets.zero,
    this.padding,
    this.isLoading = false,
    this.icon,
    this.height,
    this.maxLines = 1,
  });

  /// Outlined secondary variant — the harmless choice in a confirm dialog.
  factory Btn.unActive({
    required String text,
    VoidCallback? onPressed,
    String? icon,
    EdgeInsets margin = EdgeInsets.zero,
    int maxLines = 1,
    double? height,
  }) => Btn(
    text: text,
    onPressed: onPressed,
    icon: icon,
    margin: margin,
    maxLines: maxLines,
    height: height,
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: 12.circular,
      border: Border.all(color: theme.line),
    ),
    textStyle: theme.textStyle.copyWith(color: theme.text, fontWeight: FontWeight.w600),
  );

  /// Destructive variant (tinted red) — reject, cancel, logout.
  factory Btn.danger({
    required String text,
    VoidCallback? onPressed,
    String? icon,
    EdgeInsets margin = EdgeInsets.zero,
    bool isLoading = false,
    double? height,
  }) => Btn(
    text: text,
    onPressed: onPressed,
    icon: icon,
    margin: margin,
    isLoading: isLoading,
    height: height,
    decoration: BoxDecoration(color: theme.redBg, borderRadius: 12.circular),
    textStyle: theme.textStyle.copyWith(color: theme.red, fontWeight: FontWeight.w600),
  );

  /// Text-only variant that carries the brand color — secondary links.
  factory Btn.ghost({required String text, VoidCallback? onPressed, String? icon, double? height}) => Btn(
    text: text,
    onPressed: onPressed,
    icon: icon,
    height: height ?? 36.h,
    padding: EdgeInsets.symmetric(horizontal: 10.w),
    decoration: const BoxDecoration(),
    textStyle: theme.textStyle.copyWith(fontSize: 14.sp, color: theme.primary, fontWeight: FontWeight.w600),
  );

  /// Compact filled variant (36.h) for buttons inside cards and app bars.
  factory Btn.compact({required String text, VoidCallback? onPressed, String? icon}) => Btn(
    text: text,
    onPressed: onPressed,
    icon: icon,
    height: 36.h,
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    textStyle: theme.textStyle.copyWith(fontSize: 14.sp, color: theme.onPrimary, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? theme.textStyle.copyWith(fontWeight: FontWeight.w600, color: theme.onPrimary);
    return Opacity(
      opacity: onPressed == null && !isLoading ? 0.45 : 1,
      child: Bounce(
        onPressed: isLoading ? () {} : (onPressed ?? () {}),
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: height ?? 50.h,
          alignment: Alignment.center,
          padding: padding ?? EdgeInsets.symmetric(horizontal: 14.w),
          margin: margin,
          decoration: decoration ?? BoxDecoration(color: theme.primary, borderRadius: 12.circular),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.w,
                    valueColor: AlwaysStoppedAnimation<Color>(style.color ?? theme.onPrimary),
                  ),
                ),
                8.w.width,
              ] else if (icon != null) ...[
                AppIcon(icon!, size: 18.sp, color: style.color),
                8.w.width,
              ],
              // Flexible only kicks in when the label does not fit, so short
              // labels stay centred instead of stretching the row.
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
