part of 'bloc.dart';

/// Base of every action the notes screen can dispatch.
sealed class TaskNotesEvent {
  /// Allows the events to have const constructors.
  const TaskNotesEvent();
}

/// The screen opened or was pulled to refresh — load the notes.
final class TaskNotesStarted extends TaskNotesEvent {
  /// Fires the load.
  const TaskNotesStarted();
}

/// A note was sent from the input bar.
final class TaskNotesAdded extends TaskNotesEvent {
  /// Text of the new note.
  final String text;

  /// Carries the note text.
  const TaskNotesAdded(this.text);
}

/// A note was swiped away and its delete button tapped.
final class TaskNotesRemoved extends TaskNotesEvent {
  /// Position of the note in the task's list.
  final int index;

  /// Carries the position of the note to remove.
  const TaskNotesRemoved(this.index);
}
