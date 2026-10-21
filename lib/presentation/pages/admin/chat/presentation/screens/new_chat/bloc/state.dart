part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the new-chat screen renders itself from.
class NewChatState extends Equatable {
  /// Request lifecycle of the contacts load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// People the user may write to, filtered by [search].
  final List<UserRef> contacts;

  /// Current search text.
  final String search;

  /// True on the group tab.
  final bool group;

  /// Ids ticked for the group.
  final Set<String> selected;

  /// True while a chat is being opened or created.
  final bool busy;

  /// Id of the conversation that was opened; the screen replaces itself with it.
  final String? openedId;

  /// Builds the initial state.
  const NewChatState({
    this.status = ScreenStatus.initial,
    this.response,
    this.contacts = const [],
    this.search = '',
    this.group = false,
    this.selected = const {},
    this.busy = false,
    this.openedId,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  NewChatState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    List<UserRef>? contacts,
    String? search,
    bool? group,
    Set<String>? selected,
    bool? busy,
    String? openedId,
  }) => NewChatState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    contacts: contacts ?? this.contacts,
    search: search ?? this.search,
    group: group ?? this.group,
    selected: selected ?? this.selected,
    busy: busy ?? this.busy,
    openedId: openedId ?? this.openedId,
  );

  @override
  List<Object?> get props => [status, response, contacts, search, group, selected, busy, openedId];
}
