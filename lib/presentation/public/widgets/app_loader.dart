import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Platform-adaptive loading spinner.
///
/// iOS: [CupertinoActivityIndicator] (native grey spinning wheel).
/// Android / other: [CircularProgressIndicator] with the brand primary color.
class AppLoader extends StatelessWidget {
  /// Diameter of the spinner (defaults to 24).
  final double size;

  const AppLoader({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(radius: size / 2);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(theme.primary)),
    );
  }
}
