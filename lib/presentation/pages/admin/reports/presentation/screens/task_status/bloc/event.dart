part of 'bloc.dart';

/// Base of every action the screen can dispatch.
sealed class TaskStatusEvent {
  /// Allows the events to have const constructors.
  const TaskStatusEvent();
}

/// The screen opened — load the report.
final class TaskStatusStarted extends TaskStatusEvent {
  /// Fires the first load.
  const TaskStatusStarted();
}

/// Pull-to-refresh — reload the report.
final class TaskStatusRefreshed extends TaskStatusEvent {
  /// Reloads while keeping the current numbers visible.
  const TaskStatusRefreshed();
}

/// The user picked another period.
final class TaskStatusPeriodChanged extends TaskStatusEvent {
  /// The chosen period.
  final ReportPeriod period;

  /// Carries the chosen period.
  const TaskStatusPeriodChanged(this.period);
}
