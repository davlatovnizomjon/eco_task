import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

import 'app_icon.dart';

/// Round tinted marker with a glyph — the leading icon of list rows (task status, notification kind).
class ToneCircle extends StatelessWidget {
  /// SVG asset of the glyph.
  final String icon;

  /// Color family of the circle.
  final StatusTone tone;

  /// Diameter of the circle.
  final double? size;

  /// Builds the marker.
  const ToneCircle(this.icon, {super.key, required this.tone, this.size});

  @override
  Widget build(BuildContext context) {
    final edge = size ?? 34.w;
    return Container(
      width: edge,
      height: edge,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.bgColor, shape: BoxShape.circle),
      child: AppIcon(icon, size: edge * 0.53, color: tone.color),
    );
  }
}
