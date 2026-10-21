import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// The only way a static label → value fact is rendered (deadline, reward,
/// creator). Call it directly at every site — wrapping it in a local `_row()`
/// helper is banned, because that forks the look per screen.
class InfoRow extends StatelessWidget {
  /// Left-hand label naming the fact.
  final String label;

  /// Right-hand value; null or empty renders the em-dash placeholder.
  final String? value;

  /// SVG asset (an `AppIcons` constant) drawn before the label.
  final String? icon;

  /// Value colour override — used to highlight a deadline or a warning.
  final Color? valueColor;

  /// Builds one label → value row.
  const InfoRow({super.key, required this.label, this.value, this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[AppIcon(icon!, size: 18.sp, color: theme.grayText), 8.w.width],
          // Bounded so a long translated label truncates instead of pushing
          // the value off the row.
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardSubtitle),
          ),
          12.w.width,
          Expanded(
            flex: 2,
            child: Text(
              value == null || value!.trim().isEmpty ? TrWords.cEmptyValue.tr() : value!,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.cardTitle.copyWith(fontSize: 15.sp, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
