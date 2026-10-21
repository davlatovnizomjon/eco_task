part of 'bloc.dart';

/// Base of every action the worker home can dispatch.
sealed class TodayEvent {
  /// Allows the events to have const constructors.
  const TodayEvent();
}

/// The tab opened — load the active tasks.
final class TodayStarted extends TodayEvent {
  /// Fires the first load.
  const TodayStarted();
}

/// Pull-to-refresh — reload the active tasks.
final class TodayRefreshed extends TodayEvent {
  /// Reloads while keeping the current tasks visible.
  const TodayRefreshed();
}
