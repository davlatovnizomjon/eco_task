part of 'bloc.dart';

/// Base of every action the inbox can dispatch.
sealed class NotificationsEvent {
  /// Allows the events to have const constructors.
  const NotificationsEvent();
}

/// The inbox opened — load the first page.
final class NotificationsStarted extends NotificationsEvent {
  /// Fires the first load.
  const NotificationsStarted();
}

/// Pull-to-refresh — reload page 1.
final class NotificationsRefreshed extends NotificationsEvent {
  /// Reloads while keeping the current rows visible.
  const NotificationsRefreshed();
}

/// The user picked another filter tab.
final class NotificationsGroupChanged extends NotificationsEvent {
  /// The chosen group.
  final NotificationGroup group;

  /// Carries the chosen group.
  const NotificationsGroupChanged(this.group);
}

/// The user scrolled near the end of the list.
final class NotificationsMoreRequested extends NotificationsEvent {
  /// Loads the next page, if there is one.
  const NotificationsMoreRequested();
}

/// The user opened an entry or pressed "mark all read".
final class NotificationsMarkedRead extends NotificationsEvent {
  /// Id of the entry; null marks every entry.
  final String? id;

  /// Carries the entry id (or null for all).
  const NotificationsMarkedRead({this.id});
}
