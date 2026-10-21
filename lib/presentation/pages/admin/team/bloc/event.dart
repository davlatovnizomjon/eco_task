part of 'bloc.dart';

/// Base of every action the team directory can dispatch.
sealed class TeamEvent {
  /// Allows the events to have const constructors.
  const TeamEvent();
}

/// The screen opened — load the staff tab.
final class TeamStarted extends TeamEvent {
  /// Fires the first load.
  const TeamStarted();
}

/// Pull-to-refresh — reload page 1.
final class TeamRefreshed extends TeamEvent {
  /// Reloads while keeping the current rows visible.
  const TeamRefreshed();
}

/// The user switched between staff and clients.
final class TeamTabChanged extends TeamEvent {
  /// True for the clients tab.
  final bool clients;

  /// Carries the selected tab.
  const TeamTabChanged({required this.clients});
}

/// The search text changed.
final class TeamSearchChanged extends TeamEvent {
  /// The new search text.
  final String text;

  /// Carries the search text.
  const TeamSearchChanged(this.text);
}

/// The user scrolled near the end of the list.
final class TeamMoreRequested extends TeamEvent {
  /// Loads the next page, if there is one.
  const TeamMoreRequested();
}
