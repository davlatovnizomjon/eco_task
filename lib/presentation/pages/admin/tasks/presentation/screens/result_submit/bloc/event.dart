part of 'bloc.dart';

/// Base of every action the submit screen can dispatch.
sealed class ResultSubmitEvent {
  /// Allows the events to have const constructors.
  const ResultSubmitEvent();
}

/// The screen opened — load the task for the checklist.
final class ResultSubmitStarted extends ResultSubmitEvent {
  /// Fires the load.
  const ResultSubmitStarted();
}

/// The user typed in the summary field.
final class ResultSubmitTextChanged extends ResultSubmitEvent {
  /// Raw field text.
  final String value;

  /// Carries the new summary.
  const ResultSubmitTextChanged(this.value);
}

/// The user attached one more photo.
final class ResultSubmitPhotoAdded extends ResultSubmitEvent {
  /// Adds a placeholder photo.
  const ResultSubmitPhotoAdded();
}

/// The user pressed "send for review".
final class ResultSubmitSent extends ResultSubmitEvent {
  /// Triggers validation and, if it passes, the request.
  const ResultSubmitSent();
}
