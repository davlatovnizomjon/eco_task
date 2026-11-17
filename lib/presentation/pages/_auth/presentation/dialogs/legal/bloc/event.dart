part of 'bloc.dart';

/// Base of every action the legal sheet can dispatch.
sealed class LegalEvent {
  /// Allows the events to have const constructors.
  const LegalEvent();
}

/// The sheet opened, or "Qayta urinish" was pressed — load the text.
final class LegalStarted extends LegalEvent {
  /// Fires the load.
  const LegalStarted();
}
