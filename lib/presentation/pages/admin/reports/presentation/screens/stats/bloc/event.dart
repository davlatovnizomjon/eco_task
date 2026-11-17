part of 'bloc.dart';

/// Base of every action a statistics screen can dispatch.
sealed class StatsEvent {
  /// Allows the events to have const constructors.
  const StatsEvent();
}

/// The screen opened, or "retry" was tapped — load the current window.
final class StatsStarted extends StatsEvent {
  /// Fires the load.
  const StatsStarted();
}

/// Pull-to-refresh — reload the current window.
final class StatsRefreshed extends StatsEvent {
  /// Reloads while keeping the current numbers visible.
  const StatsRefreshed();
}

/// Another length was picked on the week / month / year switch.
final class StatsPeriodChanged extends StatsEvent {
  /// The picked length.
  final StatsPeriod period;

  /// Carries the picked length; the window resets to the current one.
  const StatsPeriodChanged(this.period);
}

/// One of the "previous" / "next" arrows was tapped.
final class StatsShifted extends StatsEvent {
  /// -1 for the previous window, +1 for the next.
  final int step;

  /// Carries the direction.
  const StatsShifted(this.step);
}

/// The download action was tapped.
final class StatsExported extends StatsEvent {
  /// Prepares the report file of the current window.
  const StatsExported();
}
