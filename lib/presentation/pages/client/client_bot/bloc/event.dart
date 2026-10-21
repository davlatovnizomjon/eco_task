part of 'bloc.dart';

/// Base of every action the client-bot screen can dispatch.
sealed class ClientBotEvent {
  /// Allows the events to have const constructors.
  const ClientBotEvent();
}

/// The user chose to sign out.
final class ClientBotSignedOut extends ClientBotEvent {
  /// Clears the session; the router then returns to the sign-in screen.
  const ClientBotSignedOut();
}
