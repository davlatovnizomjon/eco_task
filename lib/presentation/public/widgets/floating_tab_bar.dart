import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';
import 'header_action.dart';

/// One destination of the [FloatingTabBar].
class TabBarItem {
  /// SVG asset of the glyph.
  final String icon;

  /// Short label under the glyph.
  final String label;

  /// Reactive unread counter shown as a badge; null for none.
  final ValueListenable<int>? badge;

  /// True for the highlighted round call-to-action slot (the chat tab).
  final bool cta;

  /// Describes a destination.
  const TabBarItem({required this.icon, required this.label, this.badge, this.cta = false});
}

/// The role shell's bottom navigation: a rounded bar floating above the content with a tinted pill behind the
/// selected item and a round green call-to-action slot.
class FloatingTabBar extends StatelessWidget {
  /// Destinations in display order.
  final List<TabBarItem> items;

  /// Index of the selected destination.
  final int selected;

  /// Called with the tapped index.
  final ValueChanged<int> onSelected;

  /// Builds the bar.
  const FloatingTabBar({super.key, required this.items, required this.selected, required this.onSelected});

  /// Height of the bar itself.
  static double get height => 64.h;

  /// Space a scrollable must reserve at its bottom so the last row clears the bar.
  static double inset(BuildContext context) => height + 20.h + MediaQuery.of(context).padding.bottom + 12.h;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12.w,
      right: 12.w,
      bottom: 20.h + MediaQuery.of(context).padding.bottom * 0.4,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: theme.cardColor.withValues(alpha: 0.94),
          borderRadius: 32.circular,
          border: Border.all(color: theme.line, width: 0.5),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 6),
              blurRadius: 24,
              color: const Color(0xFF14281E).withValues(alpha: theme.dark ? 0.4 : 0.12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _TabButton(item: items[i], selected: i == selected, onTap: () => onSelected(i)),
              ),
          ],
        ),
      ),
    );
  }
}

/// One tappable slot of the [FloatingTabBar].
class _TabButton extends StatelessWidget {
  /// Destination drawn by this slot.
  final TabBarItem item;

  /// Whether the slot is the selected one.
  final bool selected;

  /// Called when the slot is tapped.
  final VoidCallback onTap;

  /// Builds the slot.
  const _TabButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? theme.primary : theme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ValueListenableBuilder<int>(
        valueListenable: item.badge ?? ValueNotifier<int>(0),
        builder: (context, count, _) => Stack(
          alignment: Alignment.center,
          children: [
            if (item.cta)
              Container(
                width: selected ? 62.w : 52.w,
                height: selected ? 62.w : 52.w,
                decoration: BoxDecoration(
                  color: selected ? theme.primaryTint : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                        color: theme.primary.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(item.icon, size: 26.sp, color: theme.onPrimary),
                ),
              )
            else ...[
              if (selected)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  height: 48.h,
                  decoration: BoxDecoration(color: theme.primaryTint, borderRadius: 24.circular),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(item.icon, size: 26.sp, color: color),
                  2.h.height,
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w600, color: color),
                  ),
                ],
              ),
            ],
            if (count > 0)
              Positioned(
                top: 4.h,
                left: 0,
                right: 0,
                child: Align(
                  alignment: const Alignment(0.35, 0),
                  child: CountBadge(count, ring: theme.cardColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
