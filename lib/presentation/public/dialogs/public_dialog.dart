import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import '../widgets/btn.dart';
import '../widgets/dialog_icon.dart';

/// The app's only dialog body. Errors, confirmations and success messages all
/// render through it, so a raw `AlertDialog` never appears in feature code.
/// Show it with `showCenterDialog` / `showBottomDialog`.
class PublicDialog extends StatelessWidget {
  /// Gradient header icon that carries the dialog's tone.
  final DialogIcon icon;

  /// One-line headline of the dialog.
  final String title;

  /// Explanatory body under [title]; omitted when null.
  final String? subTitle;

  /// Highlighted consequence/warning block under [subTitle].
  final String? warningText;

  /// Label of the confirming button; defaults to "OK".
  final String? activeBtnText;

  /// Label of the dismissing button; the button is omitted when null.
  final String? unActiveBtnText;

  /// Runs after the confirming button closes the dialog.
  final VoidCallback? onActiveBtnPressed;

  /// Runs after the dismissing button closes the dialog.
  final VoidCallback? onUnActiveBtnPressed;

  /// Confirming button fill; defaults to the brand color.
  final Color? activeBtnColor;

  /// Builds a dialog; the default icon is the red error one.
  PublicDialog({
    super.key,
    DialogIcon? icon,
    required this.title,
    this.subTitle,
    this.warningText,
    this.activeBtnText,
    this.unActiveBtnText,
    this.onActiveBtnPressed,
    this.onUnActiveBtnPressed,
    this.activeBtnColor,
  }) : icon = icon ?? DialogIcon();

  /// Destructive-confirmation variant — a red confirming button plus a
  /// dismiss button, required before cancelling, rejecting or signing out.
  factory PublicDialog.confirm({
    required String title,
    String? subTitle,
    String? warningText,
    required String activeBtnText,
    required String unActiveBtnText,
    VoidCallback? onActiveBtnPressed,
    VoidCallback? onUnActiveBtnPressed,
  }) => PublicDialog(
    icon: DialogIcon.warning(),
    title: title,
    subTitle: subTitle,
    warningText: warningText,
    activeBtnText: activeBtnText,
    unActiveBtnText: unActiveBtnText,
    onActiveBtnPressed: onActiveBtnPressed,
    onUnActiveBtnPressed: onUnActiveBtnPressed,
    activeBtnColor: theme.red,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        12.h.height,
        Text(title, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.cardTitle),
        if (subTitle != null) ...[
          10.h.height,
          Text(
            subTitle!,
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: theme.cardSubtitle.copyWith(height: 1.4),
          ),
        ],
        if (warningText != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            margin: 12.h.top,
            decoration: BoxDecoration(color: theme.warnBg, borderRadius: 12.circular),
            child: Text(
              warningText!,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: theme.cardSubtitle.copyWith(color: theme.warn, height: 1.3),
            ),
          ),
        18.h.height,
        // IntrinsicHeight keeps both buttons the height of the taller one, so
        // a two-line label on one side never leaves the other short.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (unActiveBtnText != null) ...[
                Expanded(
                  child: Btn.unActive(
                    text: unActiveBtnText!,
                    maxLines: 2,
                    onPressed: () {
                      Navigator.pop(context);
                      onUnActiveBtnPressed?.call();
                    },
                  ),
                ),
                10.w.width,
              ],
              Expanded(
                child: Btn(
                  text: activeBtnText ?? TrWords.cOk.tr(),
                  maxLines: 2,
                  decoration: BoxDecoration(color: activeBtnColor ?? theme.primary, borderRadius: 12.circular),
                  textStyle: theme.textStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: activeBtnColor == null ? theme.onPrimary : const Color(0xFFFFFFFF),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onActiveBtnPressed?.call();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
