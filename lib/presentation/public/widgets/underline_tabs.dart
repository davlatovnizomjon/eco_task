import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Folder-style tabs: plain labels over a hairline, the selected one green with a thick rounded underline. Tabs
/// share the width equally, or keep their own width and scroll sideways when [scrollable] is set.
class UnderlineTabs extends StatelessWidget {
  /// Tab labels.
  final List<String> labels;

  /// Index of the selected tab.
  final int selected;

  /// Called with the tapped index.
  final ValueChanged<int> onChanged;

  /// True for a long tab set: every tab is as wide as its label and the strip scrolls horizontally.
  final bool scrollable;

  /// Whether the hairline under the strip is drawn (off when the host header already draws one).
  final bool divider;

  /// Builds the strip.
  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.scrollable = false,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    /// The tabs in order; wrapped in `Expanded` when they share the width.
    final tabs = [
      for (final (i, label) in labels.indexed)
        _wrap(
          GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: BoxConstraints(minHeight: 44.h),
              padding: EdgeInsets.symmetric(horizontal: scrollable ? 14.w : 2.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: i == selected ? theme.primary : Colors.transparent, width: 3)),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.copyWith(
                  fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                  color: i == selected ? theme.primary : theme.textSecondary,
                ),
              ),
            ),
          ),
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: theme.line)) : null,
      ),
      child: scrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: tabs),
            )
          : Row(children: tabs),
    );
  }

  /// Gives [tab] an equal share of the width unless the strip scrolls.
  Widget _wrap(Widget tab) => scrollable ? tab : Expanded(child: tab);
}
