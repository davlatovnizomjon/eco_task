part of 'bloc.dart';

/// Base of every action the chat-info page can dispatch.
sealed class ChatInfoEvent {
  /// Allows the events to have const constructors.
  const ChatInfoEvent();
}

/// The page opened, or "retry" was tapped.
final class ChatInfoStarted extends ChatInfoEvent {
  /// Fires the load.
  const ChatInfoStarted();
}

/// The mute / unmute button was tapped.
final class ChatInfoMuteToggled extends ChatInfoEvent {
  /// Flips the caller's mute.
  const ChatInfoMuteToggled();
}

/// Leaving the group was confirmed.
final class ChatInfoLeft extends ChatInfoEvent {
  /// Removes the caller from the group.
  const ChatInfoLeft();
}
