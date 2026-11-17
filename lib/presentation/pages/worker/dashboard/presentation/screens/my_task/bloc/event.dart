part of 'bloc.dart';

/// Base of every action the own-task screen can dispatch.
sealed class MyTaskEvent {
  /// Allows the events to have const constructors.
  const MyTaskEvent();
}

/// The screen opened — load the task.
final class MyTaskStarted extends MyTaskEvent {
  /// Fires the first load.
  const MyTaskStarted();
}

/// Pull-to-refresh, or a return from the edit / notes screen — reload the task.
final class MyTaskRefreshed extends MyTaskEvent {
  /// Reloads while keeping the current task visible.
  const MyTaskRefreshed();
}

/// "Done" was tapped.
final class MyTaskCompleted extends MyTaskEvent {
  /// Hands the result to the manager; the screen pops afterwards.
  const MyTaskCompleted();
}

/// The "why not done" sheet was submitted.
final class MyTaskFailed extends MyTaskEvent {
  /// Why the task could not be done.
  final String reason;

  /// Carries the reason; the screen pops afterwards.
  const MyTaskFailed(this.reason);
}

/// "Write to the manager" was chosen in the "⋯" menu.
final class MyTaskChatOpened extends MyTaskEvent {
  /// Opens the direct chat with the person who gave the task.
  const MyTaskChatOpened();
}
