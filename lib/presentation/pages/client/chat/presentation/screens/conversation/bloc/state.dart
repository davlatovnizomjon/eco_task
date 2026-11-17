part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the conversation screen renders itself from.
class ConversationState extends Equatable {
  /// Request lifecycle of the first load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The conversation (header data); null until loaded.
  final ConversationModel? conversation;

  /// Messages in reading order (oldest first); unacknowledged ones are last.
  final List<ChatMessage> messages;

  /// True when older messages can still be loaded.
  final bool hasMore;

  /// True while an older page is loading.
  final bool loadingOlder;

  /// True while the live link is up.
  final bool connected;

  /// Ids of the participants that are online.
  final Set<String> online;

  /// Newest message id other participants have read (drives the "read" tick).
  final int peerRead;

  /// True once access was withdrawn; the screen closes.
  final bool revoked;

  /// The message the next send answers; null when none.
  final ChatMessage? replyingTo;

  /// True while a picked file is uploading.
  final bool uploading;

  /// Builds the initial state.
  const ConversationState({
    this.status = ScreenStatus.initial,
    this.response,
    this.conversation,
    this.messages = const [],
    this.hasMore = false,
    this.loadingOlder = false,
    this.connected = false,
    this.online = const {},
    this.peerRead = 0,
    this.revoked = false,
    this.replyingTo,
    this.uploading = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  ConversationState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    ConversationModel? conversation,
    List<ChatMessage>? messages,
    bool? hasMore,
    bool? loadingOlder,
    bool? connected,
    Set<String>? online,
    int? peerRead,
    bool? revoked,
    Object? replyingTo = _absent,
    bool? uploading,
  }) => ConversationState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    connected: connected ?? this.connected,
    online: online ?? this.online,
    peerRead: peerRead ?? this.peerRead,
    revoked: revoked ?? this.revoked,
    replyingTo: identical(replyingTo, _absent) ? this.replyingTo : replyingTo as ChatMessage?,
    uploading: uploading ?? this.uploading,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    conversation,
    messages,
    hasMore,
    loadingOlder,
    connected,
    online,
    peerRead,
    revoked,
    replyingTo,
    uploading,
  ];
}
