part of 'bloc.dart';

/// Base of every action the screen can dispatch.
sealed class TeamProgressEvent {
  /// Allows the events to have const constructors.
  const TeamProgressEvent();
}

/// The screen opened — load the report.
final class TeamProgressStarted extends TeamProgressEvent {
  /// Fires the first load.
  const TeamProgressStarted();
}

/// Pull-to-refresh — reload the report.
final class TeamProgressRefreshed extends TeamProgressEvent {
  /// Reloads while keeping the current numbers visible.
  const TeamProgressRefreshed();
}

/// The user picked another period.
final class TeamProgressPeriodChanged extends TeamProgressEvent {
  /// The chosen period.
  final ReportPeriod period;

  /// Carries the chosen period.
  const TeamProgressPeriodChanged(this.period);
}
