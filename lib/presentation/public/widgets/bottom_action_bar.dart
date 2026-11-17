import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Pinned bottom bar of forms and detail screens: a surface with a top hairline holding the screen's buttons.
class BottomActionBar extends StatelessWidget {
  /// Buttons (and optional hint) stacked inside the bar.
  final Widget child;

  /// Builds the bar.
  const BottomActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h + ScreenSize.bottomInset(context)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.line)),
      ),
      child: child,
    );
  }
}
