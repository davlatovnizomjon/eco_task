import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

/// Month grid with localized header and weekday names, a selected day and
/// optional colored dots under days. Used by the calendar tab and the
/// deadline picker.
class MonthCalendar extends StatefulWidget {
  /// The currently selected day.
  final DateTime selected;

  /// Called when a day is tapped.
  final ValueChanged<DateTime> onSelect;

  /// Called when the visible month changes (to load that month's data).
  final ValueChanged<DateTime>? onMonthChanged;

  /// Colors of the dots drawn under [day]; no dots when null.
  final List<Color> Function(DateTime day)? markers;

  /// Earliest selectable day; defaults to a year ago.
  final DateTime? firstDay;

  /// Builds the calendar.
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelect,
    this.onMonthChanged,
    this.markers,
    this.firstDay,
  });

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

/// Tracks the month being shown, which can differ from the selected day.
class _MonthCalendarState extends State<MonthCalendar> {
  /// Day that decides which month the grid displays.
  late DateTime _focused = widget.selected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return TableCalendar<Color>(
      firstDay: widget.firstDay ?? DateTime(now.year - 1),
      lastDay: DateTime(now.year + 2),
      focusedDay: _focused,
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => DateFormatter.sameDay(day, widget.selected),
      onDaySelected: (day, focused) {
        setState(() => _focused = focused);
        widget.onSelect(day);
      },
      onPageChanged: (focused) {
        _focused = focused;
        widget.onMonthChanged?.call(focused);
      },
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      daysOfWeekHeight: 28.h,
      rowHeight: 46.h,
      eventLoader: (day) => widget.markers?.call(day) ?? const [],
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: theme.textStyle,
        weekendTextStyle: theme.textStyle.copyWith(color: theme.grayText),
        selectedDecoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
        selectedTextStyle: theme.textStyle.copyWith(color: theme.onPrimary, fontWeight: FontWeight.w700),
        todayDecoration: BoxDecoration(color: theme.primaryTint, shape: BoxShape.circle),
        todayTextStyle: theme.textStyle.copyWith(color: theme.primaryDark, fontWeight: FontWeight.w700),
      ),
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (_, day) => Center(child: Text(DateFormatter.monthYear(day), style: theme.cardTitle)),
        dowBuilder: (_, day) => Center(
          child: Text(DateFormatter.weekdayShort(day), style: theme.fieldLabel.copyWith(color: theme.grayText)),
        ),
        markerBuilder: (_, day, colors) => colors.isEmpty
            ? null
            : Positioned(
                bottom: 5.h,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final color in colors.take(3))
                      Container(
                        width: 5.w,
                        height: 5.w,
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
