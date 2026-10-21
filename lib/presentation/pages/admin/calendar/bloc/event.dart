part of 'bloc.dart';

/// Base of every action the calendar can dispatch.
sealed class CalendarEvent {
  /// Allows the events to have const constructors.
  const CalendarEvent();
}

/// The tab opened — load the current month.
final class CalendarStarted extends CalendarEvent {
  /// Fires the first load.
  const CalendarStarted();
}

/// Pull-to-refresh — reload the visible month.
final class CalendarRefreshed extends CalendarEvent {
  /// Reloads while keeping the current tasks visible.
  const CalendarRefreshed();
}

/// The user swiped to another month.
final class CalendarMonthChanged extends CalendarEvent {
  /// Any day of the newly visible month.
  final DateTime month;

  /// Carries the new month.
  const CalendarMonthChanged(this.month);
}

/// The user tapped a day.
final class CalendarDaySelected extends CalendarEvent {
  /// The tapped day.
  final DateTime day;

  /// Carries the tapped day.
  const CalendarDaySelected(this.day);
}
