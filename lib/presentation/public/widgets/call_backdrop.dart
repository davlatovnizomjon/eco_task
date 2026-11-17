import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Full-screen dark green backdrop of every call screen (identical in light and dark mode); [child] is laid on top.
class CallBackdrop extends StatelessWidget {
  /// Content drawn over the gradient.
  final Widget child;

  /// Builds the backdrop.
  const CallBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1),
          radius: 1.3,
          colors: [theme.callTop, theme.callMid, theme.callBottom],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: theme.callInk),
        child: child,
      ),
    );
  }
}
