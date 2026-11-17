part of 'bloc.dart';

/// Base of every action the task list can dispatch.
sealed class TasksEvent {
  /// Allows the events to have const constructors.
  const TasksEvent();
}

/// The list screen opened — load the first page.
final class TasksStarted extends TasksEvent {
  /// Fires the first load.
  const TasksStarted();
}

/// Pull-to-refresh — reload page 1 of the current query.
final class TasksRefreshed extends TasksEvent {
  /// Reloads while keeping the current items visible.
  const TasksRefreshed();
}

/// Search text or filter changed — load the new query from page 1.
final class TasksQueryChanged extends TasksEvent {
  /// The full new query (search, filters, sort).
  final TaskQuery query;

  /// Carries the new query.
  const TasksQueryChanged(this.query);
}

/// The assignee filter was opened — load the staff it lists.
final class TasksStaffRequested extends TasksEvent {
  /// Asks for the staff list.
  const TasksStaffRequested();
}

/// The user scrolled near the end of the list.
final class TasksMoreRequested extends TasksEvent {
  /// Loads the next page, if there is one.
  const TasksMoreRequested();
}
