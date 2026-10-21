part of 'bloc.dart';

/// Base of every action the review queue can dispatch.
sealed class ReviewEvent {
  /// Allows the events to have const constructors.
  const ReviewEvent();
}

/// The queue opened — load results and expenses.
final class ReviewStarted extends ReviewEvent {
  /// Fires the first load.
  const ReviewStarted();
}

/// Pull-to-refresh — reload both lists.
final class ReviewRefreshed extends ReviewEvent {
  /// Reloads while keeping the current rows visible.
  const ReviewRefreshed();
}

/// The user switched between the results and expenses tabs.
final class ReviewTabChanged extends ReviewEvent {
  /// 0 for results, 1 for expenses.
  final int tab;

  /// Carries the selected tab.
  const ReviewTabChanged(this.tab);
}

/// The boss approved a submitted result.
final class ReviewApproved extends ReviewEvent {
  /// Id of the approved task.
  final String taskId;

  /// Carries the task id.
  const ReviewApproved(this.taskId);
}

/// The boss returned a submitted result for rework.
final class ReviewReturned extends ReviewEvent {
  /// Id of the returned task.
  final String taskId;

  /// Why the task is returned.
  final String reason;

  /// True to push the deadline back by two days.
  final bool extend;

  /// Carries the rework request.
  const ReviewReturned({required this.taskId, required this.reason, required this.extend});
}
