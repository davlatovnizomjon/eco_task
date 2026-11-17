import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Task card with a colored left edge that encodes the status — the cards of the dashboard "my tasks" stack.
class AccentTaskCard extends StatelessWidget {
  /// Color of the left edge (the status tone).
  final Color accent;

  /// Card content.
  final Widget child;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Builds the card.
  const AccentTaskCard({super.key, required this.accent, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: 18.circular,
          border: Border.all(color: theme.line),
          boxShadow: theme.stackShadow,
        ),
        child: ClipRRect(
          borderRadius: 17.circular,
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accent, width: 4)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
