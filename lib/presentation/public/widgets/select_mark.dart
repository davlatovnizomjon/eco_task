import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Shape of a [SelectMark].
enum SelectShape {
  /// Single-choice dot ring.
  radio,

  /// Multi-choice rounded square with a check.
  box,

  /// Multi-choice circle with a check (people pickers).
  circle,
}

/// The selection indicator at the end of an option row: radio ring, checkbox or round check.
class SelectMark extends StatelessWidget {
  /// Which indicator to draw.
  final SelectShape shape;

  /// Whether the option is selected.
  final bool on;

  /// Builds the indicator.
  const SelectMark({super.key, required this.shape, required this.on});

  @override
  Widget build(BuildContext context) {
    final edge = shape == SelectShape.circle ? 24.w : 22.w;
    if (shape == SelectShape.radio) {
      return Container(
        width: edge,
        height: edge,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: on ? theme.primary : theme.line, width: on ? 7.w : 2),
        ),
      );
    }
    return Container(
      width: edge,
      height: edge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? theme.primary : Colors.transparent,
        shape: shape == SelectShape.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shape == SelectShape.box ? 6.circular : null,
        border: Border.all(color: on ? theme.primary : theme.line, width: shape == SelectShape.circle ? 1.5 : 2),
      ),
      child: on ? AppIcon(AppIcons.check, size: 14.sp, color: theme.onPrimary) : null,
    );
  }
}
