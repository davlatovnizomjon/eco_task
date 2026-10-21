import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// A tappable field that looks like [InputBox] but opens a picker (date, time,
/// assignee, address) instead of a keyboard. Shows the chosen [value] or the
/// [hint], and the same red outline as inputs when [errorText] is set.
class PickerBox extends StatelessWidget {
  /// Gray label above the field.
  final String? title;

  /// Chosen value; null shows [hint].
  final String? value;

  /// Placeholder shown while nothing is chosen.
  final String hint;

  /// SVG asset (an `AppIcons` constant) drawn at the start.
  final String? leftIcon;

  /// Message under the field; a non-null value also turns the outline red.
  final String? errorText;

  /// Opens the picker.
  final VoidCallback onTap;

  /// Builds the picker field.
  const PickerBox({
    super.key,
    this.title,
    this.value,
    this.hint = '',
    this.leftIcon,
    this.errorText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.fieldLabel),
          6.h.height,
        ],
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: BoxConstraints(minHeight: 50.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: 12.circular,
              border: Border.all(color: errorText == null ? theme.line : theme.red, width: errorText == null ? 1 : 1.5),
            ),
            child: Row(
              children: [
                if (leftIcon != null) ...[AppIcon(leftIcon!, color: theme.grayText), 10.w.width],
                Expanded(
                  child: Text(
                    value ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      color: value == null ? theme.grayText : theme.text,
                    ),
                  ),
                ),
                AppIcon(AppIcons.down, size: 18.sp, color: theme.grayText),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 4.w),
            child: Text(
              errorText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.cardSubtitle.copyWith(color: theme.red),
            ),
          ),
      ],
    );
  }
}
