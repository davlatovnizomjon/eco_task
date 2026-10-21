part of 'bloc.dart';

/// Base of every action the screen can dispatch.
sealed class ReportsEvent {
  /// Allows the events to have const constructors.
  const ReportsEvent();
}

/// The screen opened — load the report.
final class ReportsStarted extends ReportsEvent {
  /// Fires the first load.
  const ReportsStarted();
}

/// Pull-to-refresh — reload the report.
final class ReportsRefreshed extends ReportsEvent {
  /// Reloads while keeping the current numbers visible.
  const ReportsRefreshed();
}

/// The user picked another period.
final class ReportsPeriodChanged extends ReportsEvent {
  /// The chosen period.
  final ReportPeriod period;

  /// Carries the chosen period.
  const ReportsPeriodChanged(this.period);
}
