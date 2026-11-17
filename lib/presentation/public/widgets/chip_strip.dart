import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// One chip of a [ChipStrip].
class StripChip {
  /// Chip label.
  final String label;

  /// Optional counter shown after the label.
  final int? count;

  /// Describes a chip.
  const StripChip(this.label, {this.count});
}

/// Single-choice row of 32 px chips (the selected one is solid dark), scrollable when it does not fit.
class ChipStrip extends StatelessWidget {
  /// Chips in display order.
  final List<StripChip> chips;

  /// Index of the selected chip.
  final int selected;

  /// Called with the tapped index.
  final ValueChanged<int> onChanged;

  /// Builds the strip.
  const ChipStrip({super.key, required this.chips, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => 6.w.width,
        itemBuilder: (context, i) {
          final on = i == selected;
          final fg = on ? theme.background : theme.textSecondary;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? theme.text : theme.cardColor,
                borderRadius: 17.circular,
                border: Border.all(color: on ? theme.text : theme.line),
              ),
              child: Text.rich(
                TextSpan(
                  text: chips[i].label,
                  children: [
                    if (chips[i].count != null)
                      TextSpan(
                        text: ' ${chips[i].count}',
                        style: TextStyle(fontSize: 12.sp, color: fg.withValues(alpha: 0.75)),
                      ),
                  ],
                ),
                maxLines: 1,
                style: theme.textStyle.copyWith(fontSize: 13.sp, color: fg),
              ),
            ),
          );
        },
      ),
    );
  }
}
