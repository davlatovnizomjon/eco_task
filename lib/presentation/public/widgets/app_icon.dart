import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

/// Draws one of the bundled SVG glyphs (`AppIcons.*`), tinted and scaled to
/// the surrounding text. The only way an icon is rendered — `Icons.*` and raw
/// `SvgPicture` calls are banned in feature code.
class AppIcon extends StatelessWidget {
  /// Asset path, one of the `AppIcons` constants.
  final String asset;

  /// Edge length of the glyph (of the whole tile for [AppIcon.tile]).
  final double? size;

  /// Tint; defaults to the secondary text color.
  final Color? color;

  /// When set, the glyph sits centered in a rounded square tinted with this
  /// tone's background; [size] is then the square's edge.
  final StatusTone? tone;

  /// Builds a plain glyph.
  const AppIcon(this.asset, {super.key, this.size, this.color}) : tone = null;

  /// Builds a glyph inside a rounded square of the [tone] family — the leading
  /// marker of list rows, notifications and dashboard cards.
  const AppIcon.tile(this.asset, {super.key, required StatusTone this.tone, double? size})
    : size = size ?? 40,
      color = null;

  @override
  Widget build(BuildContext context) {
    final edge = tone == null ? (size ?? 20.sp) : (size ?? 40).w;
    final glyph = SvgPicture.asset(
      asset,
      width: tone == null ? edge : edge * 0.5,
      height: tone == null ? edge : edge * 0.5,
      colorFilter: ColorFilter.mode(tone?.color ?? color ?? theme.textSecondary, BlendMode.srcIn),
    );
    if (tone == null) return glyph;
    return Container(
      width: edge,
      height: edge,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone!.bgColor, borderRadius: BorderRadius.circular(edge * 0.3)),
      child: glyph,
    );
  }
}
