import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import 'app_icon.dart';

/// Month calendar of the redesigned screens: a month header with arrows, a weekday row and a grid whose selected day
/// is a rounded green square, today is bold green and Sundays/disabled days are gray. Days may carry up to three
/// colored dots.
class MonthGrid extends StatefulWidget {
  /// Currently selected day.
  final DateTime selected;

  /// Called with the tapped day.
  final ValueChanged<DateTime> onSelect;

  /// Called with the first day of the month the user navigated to.
  final ValueChanged<DateTime>? onMonthChanged;

  /// Dot colors of a day; none by default.
  final List<Color> Function(DateTime day)? markers;

  /// First selectable day; earlier days are gray and inert.
  final DateTime? firstDay;

  /// Smaller header text and row height, for use inside a sheet.
  final bool compact;

  /// Builds the calendar.
  const MonthGrid({
    super.key,
    required this.selected,
    required this.onSelect,
    this.onMonthChanged,
    this.markers,
    this.firstDay,
    this.compact = false,
  });

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

/// Holds the month on display.
class _MonthGridState extends State<MonthGrid> {
  /// First day of the displayed month.
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  /// Moves the display by [step] months and reports it.
  void _shift(int step) {
    setState(() => _month = DateTime(_month.year, _month.month + step));
    widget.onMonthChanged?.call(_month);
  }

  @override
  Widget build(BuildContext context) {
    final lead = _month.weekday - 1;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final rows = ((lead + days) / 7).ceil();
    final today = DateTime.now();
    final first = widget.firstDay == null
        ? null
        : DateTime(widget.firstDay!.year, widget.firstDay!.month, widget.firstDay!.day);
    final rowHeight = (widget.compact ? 40 : 46).h;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormatter.monthYear(_month),
                style: theme.textStyle.copyWith(fontSize: widget.compact ? 15.sp : 17.sp, fontWeight: FontWeight.w700),
              ),
            ),
            for (final (step, icon) in [(-1, AppIcons.left), (1, AppIcons.right)])
              GestureDetector(
                onTap: () => _shift(step),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: (widget.compact ? 40 : 44).w,
                  height: (widget.compact ? 40 : 44).w,
                  child: Center(
                    child: AppIcon(icon, size: 24.sp, color: theme.text),
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            for (var d = 0; d < 7; d++)
              Expanded(
                child: Center(
                  child: Text(DateFormatter.weekdayShort(DateTime(2026, 1, 5 + d)), style: theme.cardSubtitle),
                ),
              ),
          ],
        ),
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: rowHeight,
            child: Row(
              children: [for (var c = 0; c < 7; c++) Expanded(child: _cell(r * 7 + c - lead + 1, days, today, first))],
            ),
          ),
      ],
    );
  }

  /// One grid cell for day number [n] (outside the month renders empty).
  Widget _cell(int n, int days, DateTime today, DateTime? first) {
    if (n < 1 || n > days) return const SizedBox.shrink();
    final day = DateTime(_month.year, _month.month, n);
    final disabled = first != null && day.isBefore(first);
    final isSelected = DateFormatter.sameDay(day, widget.selected);
    final isToday = DateFormatter.sameDay(day, today);
    final sunday = day.weekday == DateTime.sunday;
    final dots = widget.markers?.call(day) ?? const <Color>[];
    final color = isSelected
        ? theme.onPrimary
        : disabled || sunday
        ? theme.grayText
        : isToday
        ? theme.primary
        : theme.text;
    return GestureDetector(
      onTap: disabled ? null : () => widget.onSelect(day),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(color: isSelected ? theme.primary : Colors.transparent, borderRadius: 12.circular),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$n',
                style: theme.textStyle.copyWith(
                  fontSize: 15.sp,
                  height: 1.1,
                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                ),
              ),
              if (dots.isNotEmpty) ...[
                3.h.height,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final dot in dots.take(3))
                      Container(
                        width: 5.w,
                        height: 5.w,
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        decoration: BoxDecoration(color: isSelected ? theme.onPrimary : dot, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
