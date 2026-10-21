import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// The gradient square at the top of every `PublicDialog`. Its colour is what
/// tells the user at a glance whether the dialog is an error, a warning or a
/// success, so dialogs never invent their own header artwork.
class DialogIcon extends StatelessWidget {
  /// SVG asset drawn inside the gradient square.
  final String asset;

  /// Top and bottom colors of the square's gradient.
  final List<Color> colors;

  /// Builds the default red (error) icon.
  DialogIcon({super.key, this.asset = AppIcons.alert, List<Color>? colors})
    : colors = colors ?? [theme.red, theme.red.withValues(alpha: 0.75)];

  /// Green success variant used by `MessageSuccessResponse`.
  factory DialogIcon.green() => DialogIcon(asset: AppIcons.check, colors: [theme.primary, theme.primaryDark]);

  /// Amber "needs attention" variant — a confirmation is not a failure.
  factory DialogIcon.warning() =>
      DialogIcon(asset: AppIcons.alert, colors: [theme.warn, theme.warn.withValues(alpha: 0.75)]);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.line, width: 1.5),
        borderRadius: 15.circular,
      ),
      child: Padding(
        padding: 5.w.all,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
            borderRadius: 12.circular,
          ),
          child: Padding(
            padding: 12.sp.all,
            child: AppIcon(asset, size: 26.sp, color: const Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
  }
}
