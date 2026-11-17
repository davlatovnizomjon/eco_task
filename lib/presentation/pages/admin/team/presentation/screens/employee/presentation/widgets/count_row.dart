import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// One counter line of the employee card: a colored glyph, a 16 px label and the bold number at the right.
class CountRow extends StatelessWidget {
  /// SVG asset of the glyph.
  final String icon;

  /// Color of the glyph; gray when null.
  final StatusTone? tone;

  /// Label of the counter.
  final String label;

  /// The number.
  final int count;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Builds the row.
  const CountRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.tone,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 52.h),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: theme.line)),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 22.sp, color: tone?.color ?? theme.textSecondary),
          12.w.width,
          Expanded(
            child: Text(
              label,
              style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w400),
            ),
          ),
          Text(
            '$count',
            style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
