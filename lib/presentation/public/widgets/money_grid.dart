import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// One cell of a [MoneyGrid].
class MoneyCell {
  /// Small caption.
  final String label;

  /// Amount or status text.
  final String value;

  /// Color of [value]; defaults to the primary text color.
  final Color? color;

  /// Optional glyph before [value].
  final String? icon;

  /// Describes a cell.
  const MoneyCell(this.label, this.value, {this.color, this.icon});
}

/// Two-column grid of labelled amounts separated by hairlines (reward, expenses, payout status). Amounts are
/// shown side by side — the app never computes a profit from them.
class MoneyGrid extends StatelessWidget {
  /// Cells in reading order, two per row.
  final List<MoneyCell> cells;

  /// Builds the grid.
  const MoneyGrid(this.cells, {super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: 12.circular,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.line),
          borderRadius: 12.circular,
          color: theme.line,
        ),
        child: Column(
          children: [
            for (var i = 0; i < cells.length; i += 2)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 1),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _Cell(cells[i])),
                      1.w.width,
                      Expanded(child: i + 1 < cells.length ? _Cell(cells[i + 1]) : Container(color: theme.cardColor)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One surface of the [MoneyGrid].
class _Cell extends StatelessWidget {
  /// Content of the cell.
  final MoneyCell cell;

  /// Builds the cell.
  const _Cell(this.cell);

  @override
  Widget build(BuildContext context) {
    final color = cell.color ?? theme.text;
    return Container(
      color: theme.cardColor,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cell.label, style: theme.cardSubtitle),
          2.h.height,
          Row(
            children: [
              if (cell.icon != null) ...[AppIcon(cell.icon!, size: 18.sp, color: color), 6.w.width],
              Flexible(
                child: Text(
                  cell.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
