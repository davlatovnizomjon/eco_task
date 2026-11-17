part of 'bloc.dart';

/// Base of every action the task details screen can dispatch.
sealed class TaskDetailEvent {
  /// Allows the events to have const constructors.
  const TaskDetailEvent();
}

/// The screen opened — load the task.
final class TaskDetailStarted extends TaskDetailEvent {
  /// Fires the first load.
  const TaskDetailStarted();
}

/// Pull-to-refresh — reload the task.
final class TaskDetailRefreshed extends TaskDetailEvent {
  /// Reloads while keeping the current task visible.
  const TaskDetailRefreshed();
}

/// The boss approved the submitted result.
final class TaskDetailApproved extends TaskDetailEvent {
  /// Approves the task; the screen closes afterwards.
  const TaskDetailApproved();
}

/// The boss returned the task for rework.
final class TaskDetailReturned extends TaskDetailEvent {
  /// Why the task is returned.
  final String reason;

  /// True to push the deadline back by two days.
  final bool extend;

  /// Carries the rework request.
  const TaskDetailReturned({required this.reason, required this.extend});
}

/// The delete confirmation was accepted.
final class TaskDetailDeleted extends TaskDetailEvent {
  /// Deletes the task; the screen closes afterwards.
  const TaskDetailDeleted();
}
