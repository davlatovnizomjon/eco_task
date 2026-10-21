part of 'bloc.dart';

/// Base of every action the sign-in screen can dispatch.
sealed class AuthEvent {
  /// Allows the events to have const constructors.
  const AuthEvent();
}

/// The user typed in the login field.
final class AuthLoginChanged extends AuthEvent {
  /// Raw field text.
  final String login;

  /// Carries the newly typed login.
  const AuthLoginChanged(this.login);
}

/// The user typed in the password field.
final class AuthPasswordChanged extends AuthEvent {
  /// Raw field text.
  final String password;

  /// Carries the newly typed password.
  const AuthPasswordChanged(this.password);
}

/// The user pressed the sign-in button.
final class AuthSubmitted extends AuthEvent {
  /// Triggers validation and, if it passes, the login request.
  const AuthSubmitted();
}
