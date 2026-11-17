import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// iOS-style segmented control: a light track whose selected segment is filled with the brand color.
class SegmentBar extends StatelessWidget {
  /// Segment labels.
  final List<String> labels;

  /// Index of the selected segment.
  final int selected;

  /// Called with the tapped index.
  final ValueChanged<int> onChanged;

  /// Optional SVG glyph before each label (same length as [labels]); omitted when null.
  final List<String>? icons;

  /// Builds the control.
  const SegmentBar({super.key, required this.labels, required this.selected, required this.onChanged, this.icons});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: 2.w.all,
      decoration: BoxDecoration(color: theme.cardColorLight, borderRadius: 10.circular),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 30.h,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: i == selected ? theme.primary : Colors.transparent,
                    borderRadius: 8.circular,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icons != null) ...[
                        AppIcon(icons![i], size: 16.sp, color: i == selected ? theme.onPrimary : theme.text),
                        6.w.width,
                      ],
                      Flexible(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(
                            fontSize: 13.sp,
                            fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                            color: i == selected ? theme.onPrimary : theme.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
