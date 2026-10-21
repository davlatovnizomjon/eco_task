import 'package:flutter/widgets.dart';

/// Turns a raw number into the small layout objects used all over the UI, so a
/// spacing/radius value reads as `12.h.height` / `15.circular` at the call site.
extension ExtUI on num {
  /// A square gap of this size — used between icons and text in a Row/Column.
  SizedBox get size => SizedBox(width: toDouble(), height: toDouble());

  /// A horizontal gap of this size.
  SizedBox get width => SizedBox(width: toDouble());

  /// A vertical gap of this size.
  SizedBox get height => SizedBox(height: toDouble());

  /// Padding on the left edge only.
  EdgeInsets get left => EdgeInsets.only(left: toDouble());

  /// Padding on the right edge only.
  EdgeInsets get right => EdgeInsets.only(right: toDouble());

  /// Padding on the top edge only.
  EdgeInsets get top => EdgeInsets.only(top: toDouble());

  /// Padding on the bottom edge only.
  EdgeInsets get bottom => EdgeInsets.only(bottom: toDouble());

  /// Equal padding on the left and right edges.
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: toDouble());

  /// Equal padding on the top and bottom edges.
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: toDouble());

  /// Equal padding on all four edges.
  EdgeInsets get all => EdgeInsets.all(toDouble());

  /// A uniformly rounded [BorderRadius] of this radius.
  BorderRadius get circular => BorderRadius.circular(toDouble());

  /// A single circular [Radius] of this size, for per-corner radii.
  Radius get circularRadius => Radius.circular(toDouble());
}
