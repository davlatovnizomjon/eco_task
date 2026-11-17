import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Row of rounded vertical bars with a caption under each; the tallest bar is solid green, the others faded. Used by
/// the finance, task and own statistics.
class StatsBarChart extends StatelessWidget {
  /// Bar values in order.
  final List<num> values;

  /// Caption under each bar (same length as [values]).
  final List<String> labels;

  /// Builds the chart.
  const StatsBarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    /// Tallest value; the scale of the chart.
    final top = values.fold<num>(1, (m, v) => v > m ? v : m);

    /// Width of one bar: wide for few bars, slim for many.
    final barWidth = (values.length <= 4 ? 28 : (values.length <= 7 ? 18 : 12)).w;
    return SizedBox(
      height: 92.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, v) in values.indexed)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: barWidth,
                    height: (64.h * v / top).clamp(v > 0 ? 4.h : 0, 64.h).toDouble(),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: v == top ? 1 : 0.45),
                      borderRadius: 6.circular,
                    ),
                  ),
                  6.h.height,
                  Text(labels[i], style: theme.cardSubtitle.copyWith(fontSize: 11.sp)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
