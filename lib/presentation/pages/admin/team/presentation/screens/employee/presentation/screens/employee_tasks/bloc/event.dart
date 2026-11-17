part of 'bloc.dart';

/// Base of every action the employee-tasks screen can dispatch.
sealed class EmployeeTasksEvent {
  /// Allows the events to have const constructors.
  const EmployeeTasksEvent();
}

/// The screen opened, or "retry" was tapped — load the tasks.
final class EmployeeTasksStarted extends EmployeeTasksEvent {
  /// Fires the load.
  const EmployeeTasksStarted();
}

/// Pull-to-refresh — reload the tasks.
final class EmployeeTasksRefreshed extends EmployeeTasksEvent {
  /// Reloads while keeping the current tasks visible.
  const EmployeeTasksRefreshed();
}

/// A tab was tapped.
final class EmployeeTasksTabChanged extends EmployeeTasksEvent {
  /// 0 all, 1 done, 2 failed.
  final int tab;

  /// Carries the tab index.
  const EmployeeTasksTabChanged(this.tab);
}
