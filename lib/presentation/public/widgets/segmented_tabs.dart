import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Two- or three-way segmented control used for in-screen tabs (period,
/// active/history, staff/clients). Labels never overflow: each is bounded and
/// ellipsized.
class SegmentedTabs extends StatelessWidget {
  /// Labels of the segments, in order.
  final List<String> labels;

  /// Index of the selected segment.
  final int selected;

  /// Called with the tapped segment's index.
  final ValueChanged<int> onChanged;

  /// Builds the control.
  const SegmentedTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: 4.w.all,
      decoration: BoxDecoration(color: theme.cardColorLight, borderRadius: 12.circular),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 36.h,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: i == selected ? theme.cardColor : Colors.transparent,
                    borderRadius: 9.circular,
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: i == selected ? theme.text : theme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
