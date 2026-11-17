part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the call screen renders itself from.
class CallState extends Equatable {
  /// Request lifecycle of the first load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The call as the server last reported it; null until loaded.
  final CallModel? call;

  /// The conversation the call belongs to (title, kind, members); null until loaded.
  final ConversationModel? conversation;

  /// Whole seconds since the call was answered.
  final int seconds;

  /// True while an answer / decline / hang-up request runs.
  final bool busy;

  /// True while the microphone is off.
  final bool muted;

  /// True while the loudspeaker is on.
  final bool speaker;

  /// True while the camera sends pictures.
  final bool video;

  /// True while the front camera is used.
  final bool front;

  /// Zero-based page of the participant grid.
  final int page;

  /// Short line shown over the grid ("Azizbek declined"); null when none.
  final String? notice;

  /// One-shot flag: the screen should close.
  final bool closeScreen;

  /// Builds the initial state.
  const CallState({
    this.status = ScreenStatus.initial,
    this.response,
    this.call,
    this.conversation,
    this.seconds = 0,
    this.busy = false,
    this.muted = false,
    this.speaker = false,
    this.video = false,
    this.front = true,
    this.page = 0,
    this.notice,
    this.closeScreen = false,
  });

  /// Copies the state, resetting [response] and [closeScreen] unless passed so each fires once.
  CallState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    CallModel? call,
    ConversationModel? conversation,
    int? seconds,
    bool? busy,
    bool? muted,
    bool? speaker,
    bool? video,
    bool? front,
    int? page,
    Object? notice = _absent,
    bool closeScreen = false,
  }) => CallState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    call: call ?? this.call,
    conversation: conversation ?? this.conversation,
    seconds: seconds ?? this.seconds,
    busy: busy ?? this.busy,
    muted: muted ?? this.muted,
    speaker: speaker ?? this.speaker,
    video: video ?? this.video,
    front: front ?? this.front,
    page: page ?? this.page,
    notice: identical(notice, _absent) ? this.notice : notice as String?,
    closeScreen: closeScreen,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    call?.id,
    call?.status,
    call?.parties.map((p) => '${p.user.id}:${p.state.name}').join(','),
    conversation?.id,
    seconds,
    busy,
    muted,
    speaker,
    video,
    front,
    page,
    notice,
    closeScreen,
  ];
}
