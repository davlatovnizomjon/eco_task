import 'package:flutter/material.dart';
import 'package:flutter_bounce/flutter_bounce.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Round control of the call bar (speaker, camera, mute, flip, ...): a veil circle, or a white one while [on].
class CallRoundButton extends StatelessWidget {
  /// SVG asset of the glyph.
  final String icon;

  /// Accessibility label of the control.
  final String label;

  /// True for the highlighted (white) state.
  final bool on;

  /// Tap handler; null disables the button.
  final VoidCallback? onTap;

  /// Builds the button.
  const CallRoundButton({super.key, required this.icon, required this.label, this.on = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final edge = 58.w;
    return Semantics(
      button: true,
      label: label,
      child: Bounce(
        onPressed: onTap ?? () {},
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: edge,
          height: edge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? theme.callInk.withValues(alpha: 0.92) : theme.callVeil,
          ),
          child: AppIcon(icon, size: 26.sp, color: on ? theme.callInkDark : theme.callInk),
        ),
      ),
    );
  }
}

/// Wide red pill that ends or leaves a call.
class CallEndButton extends StatelessWidget {
  /// Accessibility label of the control.
  final String label;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Builds the button.
  const CallEndButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Bounce(
        onPressed: onTap ?? () {},
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 96.w,
          height: 58.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29.r),
            color: theme.callRed,
            boxShadow: [
              BoxShadow(color: theme.callRed.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: AppIcon(AppIcons.callEnd, size: 30.sp, color: theme.callInk),
        ),
      ),
    );
  }
}

/// Big round answer / decline button of the incoming-call screen, with the soft double ring around it.
class CallPickButton extends StatelessWidget {
  /// Accessibility label of the control.
  final String label;

  /// True for the green "answer" look, false for the red "decline" look.
  final bool accept;

  /// SVG asset of the glyph.
  final String icon;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Builds the button.
  const CallPickButton({super.key, required this.label, required this.accept, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Bounce(
        onPressed: onTap ?? () {},
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 72.w,
          height: 72.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accept ? theme.callGreen : theme.callRed,
            boxShadow: [
              BoxShadow(color: theme.callVeil.withValues(alpha: 0.08), spreadRadius: 10.w),
              BoxShadow(color: theme.callVeil.withValues(alpha: 0.04), spreadRadius: 22.w),
            ],
          ),
          child: AppIcon(icon, size: 30.sp, color: theme.callInk),
        ),
      ),
    );
  }
}
