part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the group-edit page renders itself from.
class GroupEditState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The group as the server has it; the draft is compared with it on save.
  final ConversationModel? original;

  /// Draft title.
  final String title;

  /// Draft member list.
  final List<UserRef> members;

  /// People that may be added (everyone the caller can message).
  final List<UserRef> candidates;

  /// True after a save was attempted: an empty title turns red.
  final bool showErrors;

  /// True while the draft is being applied.
  final bool busy;

  /// One-shot flag: the draft was applied, so the page should close.
  final bool saved;

  /// Builds the initial state.
  /// The photo uploaded in this session, waiting for save; null when unchanged.
  final FileAttachment? photo;

  /// True while the photo uploads.
  final bool uploading;

  const GroupEditState({
    this.status = ScreenStatus.initial,
    this.response,
    this.original,
    this.title = '',
    this.members = const [],
    this.candidates = const [],
    this.showErrors = false,
    this.busy = false,
    this.saved = false,
    this.photo,
    this.uploading = false,
  });

  /// Copies the state, resetting [response] and [saved] unless passed so each fires once.
  GroupEditState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    ConversationModel? original,
    String? title,
    List<UserRef>? members,
    List<UserRef>? candidates,
    bool? showErrors,
    bool? busy,
    bool saved = false,
    FileAttachment? photo,
    bool? uploading,
  }) => GroupEditState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    original: original ?? this.original,
    title: title ?? this.title,
    members: members ?? this.members,
    candidates: candidates ?? this.candidates,
    showErrors: showErrors ?? this.showErrors,
    busy: busy ?? this.busy,
    saved: saved,
    photo: photo ?? this.photo,
    uploading: uploading ?? this.uploading,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    original,
    title,
    members,
    candidates,
    showErrors,
    busy,
    saved,
    photo,
    uploading,
  ];
}
