part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the own-task screen renders itself from.
class MyTaskState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The loaded task (cached or fresh); null until the first answer.
  final TaskModel? task;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// True while a closing action (done / failed / delete) runs.
  final bool busy;

  /// One-shot flag: the task was closed or deleted, so the screen should pop.
  final bool closeScreen;

  /// Builds the initial state.
  const MyTaskState({
    this.status = ScreenStatus.initial,
    this.response,
    this.task,
    this.refreshing = false,
    this.busy = false,
    this.closeScreen = false,
  });

  /// Copies the state, resetting [response] and [closeScreen] unless passed so each fires once.
  MyTaskState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    TaskModel? task,
    bool? refreshing,
    bool? busy,
    bool closeScreen = false,
  }) => MyTaskState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    task: task ?? this.task,
    refreshing: refreshing ?? this.refreshing,
    busy: busy ?? this.busy,
    closeScreen: closeScreen,
  );

  @override
  List<Object?> get props => [status, response, task, refreshing, busy, closeScreen];
}
