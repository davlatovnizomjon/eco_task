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

/// A photo, document, voice note or video circle was picked or recorded: upload it, then send it as a message.
final class ConversationFileSent extends ConversationEvent {
  /// The picked or recorded file.
  final PickedFile file;

  /// Carries the file.
  const ConversationFileSent(this.file);
}

/// "Javob berish" was chosen on [message], or the reply bar was closed (null).
final class ConversationReplyChanged extends ConversationEvent {
  /// The message being answered; null clears the reply bar.
  final ChatMessage? message;

  /// Carries the message.
  const ConversationReplyChanged(this.message);
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

/// The author saved a new text for one of their messages.
final class ConversationMessageEdited extends ConversationEvent {
  /// Server id of the message.
  final int id;

  /// The new text.
  final String text;

  /// Carries the edit.
  const ConversationMessageEdited(this.id, this.text);
}

/// A message was deleted (its text is wiped, the placeholder stays).
final class ConversationMessageDeleted extends ConversationEvent {
  /// Server id of the message.
  final int id;

  /// Carries the id.
  const ConversationMessageDeleted(this.id);
}

/// An emoji was picked (or the same one tapped again to take it back) on a message.
final class ConversationReacted extends ConversationEvent {
  /// Server id of the message.
  final int id;

  /// The emoji; null removes the caller's reaction.
  final String? emoji;

  /// Carries the reaction.
  const ConversationReacted(this.id, this.emoji);
}

/// A message was pinned, or the pin cleared.
final class ConversationPinned extends ConversationEvent {
  /// Server id of the message to pin; null clears the pin.
  final int? id;

  /// Carries the id.
  const ConversationPinned(this.id);
}
