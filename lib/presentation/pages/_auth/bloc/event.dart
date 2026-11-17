part of 'bloc.dart';

/// Base of every action the sign-in screen can dispatch.
sealed class AuthEvent {
  /// Allows the events to have const constructors.
  const AuthEvent();
}

/// The login field was edited.
final class AuthLoginChanged extends AuthEvent {
  /// New login text.
  final String login;

  /// Stores [login].
  const AuthLoginChanged(this.login);
}

/// The password field was edited.
final class AuthPasswordChanged extends AuthEvent {
  /// New password text.
  final String password;

  /// Stores [password].
  const AuthPasswordChanged(this.password);
}

/// The "Kirish" button was pressed.
final class AuthSubmitted extends AuthEvent {
  /// Validates the fields and signs in.
  const AuthSubmitted();
}

/// One second passed while the account is locked; refreshes the countdown.
final class AuthTicked extends AuthEvent {
  /// Recomputes the remaining lock time and unlocks when it reaches zero.
  const AuthTicked();
}
