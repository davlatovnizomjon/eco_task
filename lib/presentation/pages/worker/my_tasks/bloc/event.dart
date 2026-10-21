part of 'bloc.dart';

/// Base of every action the worker's task list can dispatch.
sealed class MyTasksEvent {
  /// Allows the events to have const constructors.
  const MyTasksEvent();
}

/// The screen opened — load the selected tab.
final class MyTasksStarted extends MyTasksEvent {
  /// Fires the first load.
  const MyTasksStarted();
}

/// Pull-to-refresh — reload page 1 of the selected tab.
final class MyTasksRefreshed extends MyTasksEvent {
  /// Reloads while keeping the current items visible.
  const MyTasksRefreshed();
}

/// The user switched between active and history.
final class MyTasksTabChanged extends MyTasksEvent {
  /// 0 for active, 1 for history.
  final int tab;

  /// Carries the selected tab.
  const MyTasksTabChanged(this.tab);
}

/// The user scrolled near the end of the list.
final class MyTasksMoreRequested extends MyTasksEvent {
  /// Loads the next page, if there is one.
  const MyTasksMoreRequested();
}
