part of 'bloc.dart';

/// Base of every action the help sheet can dispatch.
sealed class SupportEvent {
  /// Allows the events to have const constructors.
  const SupportEvent();
}

/// The sheet opened, or "Qayta urinish" was pressed — load the contacts.
final class SupportStarted extends SupportEvent {
  /// Fires the load.
  const SupportStarted();
}
