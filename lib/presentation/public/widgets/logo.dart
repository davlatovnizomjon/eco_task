import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// The `eco.tasks` wordmark in the brand font; [short] draws only `eco`.
/// The dot always carries the brand green.
class Logo extends StatelessWidget {
  /// Font size of the wordmark.
  final double size;

  /// Text color override (for dark backgrounds).
  final Color? color;

  /// Draws just `eco` instead of `eco.tasks`.
  final bool short;

  /// Builds the wordmark.
  const Logo({super.key, required this.size, this.color, this.short = false});

  @override
  Widget build(BuildContext context) {
    final base = theme.logoStyle.copyWith(fontSize: size, color: color);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'eco'),
          if (!short) ...[
            TextSpan(
              text: '.',
              style: TextStyle(color: theme.primary),
            ),
            const TextSpan(text: 'tasks'),
          ],
        ],
      ),
    );
  }
}
