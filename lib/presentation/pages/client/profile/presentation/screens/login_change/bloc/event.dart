part of 'bloc.dart';

/// Base of every action the login and password form can dispatch.
sealed class LoginChangeEvent {
  /// Allows the events to have const constructors.
  const LoginChangeEvent();
}

/// The login field was edited.
final class LoginChangeLoginEdited extends LoginChangeEvent {
  /// New login text.
  final String value;

  /// Stores [value].
  const LoginChangeLoginEdited(this.value);
}

/// The current-password field was edited.
final class LoginChangeCurrentEdited extends LoginChangeEvent {
  /// New text.
  final String value;

  /// Stores [value].
  const LoginChangeCurrentEdited(this.value);
}

/// The new-password field was edited.
final class LoginChangeNextEdited extends LoginChangeEvent {
  /// New text.
  final String value;

  /// Stores [value].
  const LoginChangeNextEdited(this.value);
}

/// The repeat-password field was edited.
final class LoginChangeRepeatEdited extends LoginChangeEvent {
  /// New text.
  final String value;

  /// Stores [value].
  const LoginChangeRepeatEdited(this.value);
}

/// "Save" was pressed.
final class LoginChangeSubmitted extends LoginChangeEvent {
  /// Validates and saves the login and/or the password.
  const LoginChangeSubmitted();
}
