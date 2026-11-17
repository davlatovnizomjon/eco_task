import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// One arc of a [RingChart]: its weight and its color.
typedef RingSegment = ({num value, Color color});

/// Donut chart: colored arcs proportional to their values around a hollow centre that holds [child] — the weekly
/// progress of the dashboard, the percent ring of a person and the report statistics.
class RingChart extends StatelessWidget {
  /// Arcs in drawing order, clockwise from the top.
  final List<RingSegment> segments;

  /// Outer diameter of the ring.
  final double size;

  /// Thickness of the ring band.
  final double thickness;

  /// Value the arcs are measured against; defaults to the sum of [segments].
  final num? total;

  /// Color of the band left uncovered by the arcs; defaults to the light surface.
  final Color? track;

  /// Content of the hollow centre (a number, a caption).
  final Widget? child;

  /// Builds the chart.
  const RingChart({
    super.key,
    required this.segments,
    required this.size,
    required this.thickness,
    this.total,
    this.track,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          segments: segments,
          total: total ?? segments.fold<num>(0, (sum, s) => sum + s.value),
          thickness: thickness,
          track: track ?? theme.cardColorLight,
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Paints the track and the arcs of a [RingChart].
class _RingPainter extends CustomPainter {
  /// Arcs in drawing order.
  final List<RingSegment> segments;

  /// Value of a full circle.
  final num total;

  /// Thickness of the band.
  final double thickness;

  /// Color of the uncovered band.
  final Color track;

  /// Builds the painter.
  const _RingPainter({required this.segments, required this.total, required this.thickness, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    /// Arc bounds: the stroke is centred on this rectangle's edge.
    final rect = (Offset.zero & size).deflate(thickness / 2);

    /// Stroke shared by the track and the arcs.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
    if (total <= 0) return;

    /// Angle where the next arc starts; the first one starts at 12 o'clock.
    var start = -math.pi / 2;
    for (final segment in segments) {
      /// Angle covered by this arc.
      final sweep = math.pi * 2 * (segment.value / total);
      canvas.drawArc(rect, start, sweep, false, paint..color = segment.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.segments != segments || old.total != total || old.thickness != thickness || old.track != track;
}
