part of 'bloc.dart';

/// Base of every action the role shell can dispatch.
sealed class MainEvent {
  /// Allows the events to have const constructors.
  const MainEvent();
}

/// The shell opened — refresh the unread badge.
final class MainStarted extends MainEvent {
  /// Fires the badge refresh.
  const MainStarted();
}
