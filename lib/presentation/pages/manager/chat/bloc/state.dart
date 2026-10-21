part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the conversation list renders itself from.
class ChatsState extends Equatable {
  /// Request lifecycle of the first load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Conversations, newest activity first.
  final List<ConversationModel> items;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const ChatsState({this.status = ScreenStatus.initial, this.response, this.items = const [], this.refreshing = false});

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  ChatsState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    List<ConversationModel>? items,
    bool? refreshing,
  }) => ChatsState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    items: items ?? this.items,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, items, refreshing];
}
