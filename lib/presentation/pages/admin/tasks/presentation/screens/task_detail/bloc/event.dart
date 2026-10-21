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

/// A comment was sent.
final class TaskDetailCommentSent extends TaskDetailEvent {
  /// Comment text.
  final String text;

  /// Carries the comment text.
  const TaskDetailCommentSent(this.text);
}

/// A worker reported progress.
final class TaskDetailProgressReported extends TaskDetailEvent {
  /// Pieces completed so far by the signed-in worker.
  final int done;

  /// True when the worker reports the task cannot be done.
  final bool cant;

  /// Optional note posted as a comment.
  final String note;

  /// Carries the progress report.
  const TaskDetailProgressReported({required this.done, required this.cant, this.note = ''});
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

/// The boss confirmed canceling the task.
final class TaskDetailCanceled extends TaskDetailEvent {
  /// Cancels the task; the screen closes afterwards.
  const TaskDetailCanceled();
}
