part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the chat-info page renders itself from.
class ChatInfoState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The conversation described; null until loaded.
  final ConversationModel? conversation;

  /// The other person's account (direct chats); null for groups.
  final AppUser? person;

  /// The other person's open tasks (direct chats).
  final int activeTasks;

  /// True while leaving the group.
  final bool busy;

  /// One-shot flag: the caller left, so the page should close.
  final bool left;

  /// Builds the initial state.
  const ChatInfoState({
    this.status = ScreenStatus.initial,
    this.response,
    this.conversation,
    this.person,
    this.activeTasks = 0,
    this.busy = false,
    this.left = false,
  });

  /// Copies the state, resetting [response] and [left] unless passed so each fires once.
  ChatInfoState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    ConversationModel? conversation,
    AppUser? person,
    int? activeTasks,
    bool? busy,
    bool left = false,
  }) => ChatInfoState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    conversation: conversation ?? this.conversation,
    person: person ?? this.person,
    activeTasks: activeTasks ?? this.activeTasks,
    busy: busy ?? this.busy,
    left: left,
  );

  @override
  List<Object?> get props => [status, response, conversation, person, activeTasks, busy, left];
}
