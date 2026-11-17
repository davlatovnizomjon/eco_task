part of 'bloc.dart';

/// Base of every action the new-chat screen can dispatch.
sealed class NewChatEvent {
  /// Allows the events to have const constructors.
  const NewChatEvent();
}

/// The screen opened — load the people one may write to.
final class NewChatStarted extends NewChatEvent {
  /// Fires the first load.
  const NewChatStarted();
}

/// The search text changed.
final class NewChatSearched extends NewChatEvent {
  /// New search text.
  final String query;

  /// Carries the text.
  const NewChatSearched(this.query);
}

/// The user switched between the direct and the group tab.
final class NewChatTabChanged extends NewChatEvent {
  /// True for the group tab.
  final bool group;

  /// Carries the tab.
  const NewChatTabChanged({required this.group});
}

/// The user tapped a person in the direct tab — open the chat with them.
final class NewChatPersonPicked extends NewChatEvent {
  /// Account id.
  final String userId;

  /// Carries the id.
  const NewChatPersonPicked(this.userId);
}

/// The user ticked or unticked a person in the group tab.
final class NewChatMemberToggled extends NewChatEvent {
  /// Account id.
  final String userId;

  /// Carries the id.
  const NewChatMemberToggled(this.userId);
}

/// The user pressed "create" in the group tab.
final class NewChatGroupSubmitted extends NewChatEvent {
  /// Group title.
  final String title;

  /// Carries the title.
  const NewChatGroupSubmitted(this.title);
}

/// "Select all" was tapped on the group member list.
final class NewChatAllToggled extends NewChatEvent {
  /// Selects every listed contact, or clears the selection when all are already selected.
  const NewChatAllToggled();
}
