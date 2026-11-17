part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the notes screen renders itself from.
class TaskNotesState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Notes of the task in the order the server keeps them (oldest first).
  final List<CommentModel> notes;

  /// True while a load is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// True while a note is being added or removed.
  final bool busy;

  /// Builds the initial state.
  const TaskNotesState({
    this.status = ScreenStatus.initial,
    this.response,
    this.notes = const [],
    this.refreshing = false,
    this.busy = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so it fires once.
  TaskNotesState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    List<CommentModel>? notes,
    bool? refreshing,
    bool? busy,
  }) => TaskNotesState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    notes: notes ?? this.notes,
    refreshing: refreshing ?? this.refreshing,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [status, response, notes, refreshing, busy];
}
