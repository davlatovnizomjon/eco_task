part of 'bloc.dart';

/// Base of every action the conversation list can dispatch.
sealed class ChatsEvent {
  /// Allows the events to have const constructors.
  const ChatsEvent();
}

/// The tab opened — load the conversations.
final class ChatsStarted extends ChatsEvent {
  /// Fires the first load.
  const ChatsStarted();
}

/// Pull-to-refresh, or returning from a conversation — reload the list.
final class ChatsRefreshed extends ChatsEvent {
  /// Reloads while keeping the current rows visible.
  const ChatsRefreshed();
}
