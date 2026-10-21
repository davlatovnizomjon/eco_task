import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// The app's only text field. It carries the label, the surface, the error
/// outline and the error text, so a feature never hand-rolls a `TextField`
/// and every form expresses invalidity the same way.
class InputBox extends StatelessWidget {
  /// Controller holding the typed text.
  final TextEditingController? controller;

  /// Fires on every keystroke; forms use it to clear this field's error.
  final ValueChanged<String>? onChanged;

  /// Gray label above the field. Include the unit when the value has one.
  final String? title;

  /// Placeholder inside the field.
  final String hint;

  /// Message under the field; a non-null value also turns the outline red.
  final String? errorText;

  /// Hides the typed characters — used by the password field.
  final bool isPassword;

  /// Keyboard layout to raise.
  final TextInputType inputType;

  /// Formatters applied while typing (phone mask, digits-only).
  final List<TextInputFormatter> inputFormatters;

  /// SVG asset (an `AppIcons` constant) drawn at the start of the field.
  final String? leftIcon;

  /// Trailing widget inside the field, e.g. a reveal-password button.
  final Widget? rightWidget;

  /// Focus node, so a form can move focus between fields.
  final FocusNode? focusNode;

  /// Minimum visible lines; values above 1 make a multi-line note field.
  final int lines;

  /// Builds the field.
  const InputBox({
    super.key,
    this.controller,
    this.onChanged,
    this.title,
    this.hint = '',
    this.errorText,
    this.isPassword = false,
    this.inputType = TextInputType.text,
    this.inputFormatters = const [],
    this.leftIcon,
    this.rightWidget,
    this.focusNode,
    this.lines = 1,
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
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: 12.circular,
            border: Border.all(color: errorText == null ? theme.line : theme.red, width: errorText == null ? 1 : 1.5),
          ),
          child: Row(
            crossAxisAlignment: lines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (leftIcon != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, lines > 1 ? 15.h : 0, 0, 0),
                  child: AppIcon(leftIcon!, color: theme.grayText),
                )
              else
                14.w.width,
              if (leftIcon != null) 10.w.width,
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: lines > 1 ? TextInputType.multiline : inputType,
                  inputFormatters: inputFormatters,
                  obscureText: isPassword,
                  autocorrect: false,
                  minLines: lines,
                  maxLines: isPassword ? 1 : (lines > 1 ? lines + 2 : 1),
                  onChanged: onChanged,
                  cursorColor: theme.primary,
                  style: theme.textStyle,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: theme.textStyle.copyWith(fontWeight: FontWeight.w400, color: theme.grayText),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                  ),
                ),
              ),
              if (rightWidget != null) ...[rightWidget!, 10.w.width],
            ],
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
