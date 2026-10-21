part of 'bloc.dart';

/// Base of every action the employee profile can dispatch.
sealed class EmployeeEvent {
  /// Allows the events to have const constructors.
  const EmployeeEvent();
}

/// The profile opened — load the account and tasks.
final class EmployeeStarted extends EmployeeEvent {
  /// Fires the first load.
  const EmployeeStarted();
}

/// Pull-to-refresh — reload the account and tasks.
final class EmployeeRefreshed extends EmployeeEvent {
  /// Reloads while keeping the current data visible.
  const EmployeeRefreshed();
}

/// The user switched between active and history.
final class EmployeeTabChanged extends EmployeeEvent {
  /// 0 for active, 1 for history.
  final int tab;

  /// Carries the selected tab.
  const EmployeeTabChanged(this.tab);
}
