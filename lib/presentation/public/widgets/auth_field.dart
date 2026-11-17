import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Labelled 52 px text field of the sign-in form: a leading glyph, the input and an optional trailing widget. The
/// border turns green with a soft halo while focused and red when [invalid].
/// Every change is animated: the border and glyph colours fade and the halo fades in and out.
class AuthField extends StatefulWidget {
  /// Label above the field.
  final String label;

  /// Placeholder shown while empty.
  final String hint;

  /// SVG asset of the leading glyph.
  final String icon;

  /// Text controller.
  final TextEditingController controller;

  /// Called on every edit.
  final ValueChanged<String> onChanged;

  /// Whether the field is drawn red.
  final bool invalid;

  /// Hides the typed characters.
  final bool obscure;

  /// Widget at the end of the field (the show/hide password button); omitted when null.
  final Widget? trailing;

  /// Keyboard action pressed on the keyboard's confirm key.
  final ValueChanged<String>? onSubmitted;

  /// Builds the field.
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onChanged,
    this.invalid = false,
    this.obscure = false,
    this.trailing,
    this.onSubmitted,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

/// Tracks the focus to draw the halo.
class _AuthFieldState extends State<AuthField> {
  /// Length of every state change (border, halo, glyph colour, message).
  static const _duration = Duration(milliseconds: 220);

  /// Focus of the inner input.
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final border = widget.invalid ? theme.red : (focused ? theme.primary : theme.line);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.fieldLabel),
        6.h.height,
        AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOut,
          height: 52.h,
          padding: EdgeInsets.fromLTRB(14.w, 0, 4.w, 0),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: 14.circular,
            border: Border.all(color: border),
            // Always one shadow, transparent when unused, so the halo fades in and out instead of popping.
            boxShadow: [
              BoxShadow(
                color: focused && !widget.invalid ? theme.primaryTint : theme.primaryTint.withValues(alpha: 0),
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: widget.invalid ? theme.red : (focused ? theme.primary : theme.grayText)),
                duration: _duration,
                builder: (context, color, _) => AppIcon(widget.icon, size: 20.sp, color: color),
              ),
              10.w.width,
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: theme.primary,
                  style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w400),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: theme.textStyle.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: theme.grayText.withValues(alpha: 0.65),
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
      ],
    );
  }
}
