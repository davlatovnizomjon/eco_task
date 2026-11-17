import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Frosted rounded panel that holds the call controls at the bottom of a call screen.
class CallGlassBar extends StatelessWidget {
  /// The controls, usually a [Row] of call buttons.
  final Widget child;

  /// Builds the panel.
  const CallGlassBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(41.r);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.callGlass,
            borderRadius: radius,
            border: Border.all(color: theme.callVeil.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
