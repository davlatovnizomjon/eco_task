part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the submit screen renders itself from.
class ResultSubmitState extends Equatable {
  /// Request lifecycle of the load and the send.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The task being submitted; null until the first answer.
  final TaskModel? task;

  /// Raw summary text.
  final String text;

  /// Number of attached photo placeholders.
  final int photos;

  /// Flipped on the first send attempt; until then nothing turns red.
  final bool showErrors;

  /// One-shot: the result was sent and both screens should close.
  final bool saved;

  /// Builds the initial state.
  const ResultSubmitState({
    this.status = ScreenStatus.initial,
    this.response,
    this.task,
    this.text = '',
    this.photos = 0,
    this.showErrors = false,
    this.saved = false,
  });

  /// Validation message when no photo is attached, independent of [showErrors].
  String? get photoError => photos == 0 ? TrWords.vPhotoRequired.tr() : null;

  /// Photo error the section should display — nothing before the first send.
  String? get visiblePhotoError => showErrors ? photoError : null;

  /// Copies the state; [response] and [saved] reset unless passed, so each
  /// fires once per emit.
  ResultSubmitState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    TaskModel? task,
    String? text,
    int? photos,
    bool? showErrors,
    bool saved = false,
  }) => ResultSubmitState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    task: task ?? this.task,
    text: text ?? this.text,
    photos: photos ?? this.photos,
    showErrors: showErrors ?? this.showErrors,
    saved: saved,
  );

  @override
  List<Object?> get props => [status, response, task, text, photos, showErrors, saved];
}
