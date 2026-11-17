part of 'bloc.dart';

/// Base of every action the "today's tasks" list can dispatch.
sealed class TodayEvent {
  /// Allows the events to have const constructors.
  const TodayEvent();
}

/// The screen opened — load the day's tasks.
final class TodayStarted extends TodayEvent {
  /// Fires the first load.
  const TodayStarted();
}

/// Pull-to-refresh — reload the day's tasks.
final class TodayRefreshed extends TodayEvent {
  /// Reloads while keeping the current list visible.
  const TodayRefreshed();
}

/// A quick-filter chip was tapped.
final class TodayFilterChanged extends TodayEvent {
  /// Index of the chip: 0 all, 1 in progress, 2 new, 3 overdue.
  final int filter;

  /// Selects the chip [filter].
  const TodayFilterChanged(this.filter);
}
