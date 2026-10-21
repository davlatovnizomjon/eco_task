part of 'bloc.dart';

/// Base of every action the conversation screen can dispatch.
sealed class ConversationEvent {
  /// Allows the events to have const constructors.
  const ConversationEvent();
}

/// The screen opened — load the conversation and history, then go live.
final class ConversationStarted extends ConversationEvent {
  /// Fires the first load.
  const ConversationStarted();
}

/// The user asked for messages older than the oldest shown.
final class ConversationOlderRequested extends ConversationEvent {
  /// Loads the next older page, if there is one.
  const ConversationOlderRequested();
}

/// The user sent a message.
final class ConversationMessageSent extends ConversationEvent {
  /// Message text.
  final String text;

  /// Carries the text.
  const ConversationMessageSent(this.text);
}

/// The user pressed a failed message to send it again.
final class ConversationMessageRetried extends ConversationEvent {
  /// Client id of the failed message.
  final String clientMsgId;

  /// Carries the id.
  const ConversationMessageRetried(this.clientMsgId);
}

/// Internal: the socket delivered an event.
final class ConversationSocketEvent extends ConversationEvent {
  /// The socket event.
  final ChatEvent event;

  /// Carries the socket event.
  const ConversationSocketEvent(this.event);
}

/// Internal: the socket did not acknowledge a send in time — fall back to REST.
final class ConversationSendTimedOut extends ConversationEvent {
  /// Client id of the unacknowledged message.
  final String clientMsgId;

  /// Carries the id.
  const ConversationSendTimedOut(this.clientMsgId);
}
