import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:eco_task/constants/constants.dart';

/// The flag of a UI language (Uzbekistan for both Uzbek scripts, Russia for Russian) with softly rounded corners.
class FlagIcon extends StatelessWidget {
  /// Locale whose flag is drawn.
  final Locale locale;

  /// Width of the flag; the height keeps the 3:2 ratio.
  final double width;

  /// Builds the flag.
  const FlagIcon(this.locale, {super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: (width * 0.14).circular,
      child: SvgPicture.asset(
        locale.languageCode == 'ru' ? AppImages.flagRu : AppImages.flagUz,
        width: width,
        height: width * 2 / 3,
      ),
    );
  }
}
