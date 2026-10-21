import 'package:flutter/material.dart';
import 'package:flutter_bounce/flutter_bounce.dart';

import 'package:eco_task/constants/constants.dart';

/// The app's card/panel surface. Every raised block of content goes through
/// it, so a hand-rolled `Container(decoration: BoxDecoration(...))` never
/// appears in feature code and one edit restyles every panel.
class CardWidget extends StatelessWidget {
  /// Content laid inside the card's padding.
  final Widget child;

  /// Space inside the card; defaults to the standard 14/12 rhythm.
  final EdgeInsets? padding;

  /// Space around the card.
  final EdgeInsets? margin;

  /// Full decoration override; defaults to `theme.cardDecor`.
  final BoxDecoration? decoration;

  /// Surface colour override, applied on top of the default decoration.
  final Color? color;

  /// Corner radius override, applied on top of the default decoration.
  final double? radius;

  /// Border override — used to mark a selected or invalid card.
  final Border? border;

  /// Shadow override — the bottom bar passes `theme.bottomBarShadow`.
  final List<BoxShadow>? shadow;

  /// Fixed height; null lets the card size to its [child].
  final double? height;

  /// Tap handler; when given, the card animates on press.
  final VoidCallback? onTap;

  /// Builds a card surface around [child].
  const CardWidget({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.decoration,
    this.color,
    this.radius,
    this.border,
    this.shadow,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      height: height,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      margin: margin,
      decoration:
          decoration ??
          theme.cardDecor.copyWith(color: color, borderRadius: radius?.circular, border: border, boxShadow: shadow),
      child: child,
    );
    if (onTap == null) return surface;
    return Bounce(onPressed: onTap!, duration: const Duration(milliseconds: 150), child: surface);
  }
}
