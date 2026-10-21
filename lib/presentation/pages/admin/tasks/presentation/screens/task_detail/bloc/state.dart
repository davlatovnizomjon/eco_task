part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the task details screen renders itself from.
class TaskDetailState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The loaded task (cached or fresh); null until the first answer.
  final TaskModel? task;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// True while an action (comment, approve, ...) is being sent.
  final bool busy;

  /// One-shot: the action finished and the screen should pop.
  final bool closeScreen;

  /// Builds the initial state.
  const TaskDetailState({
    this.status = ScreenStatus.initial,
    this.response,
    this.task,
    this.refreshing = false,
    this.busy = false,
    this.closeScreen = false,
  });

  /// Copies the state; [response] and [closeScreen] reset unless passed, so
  /// each fires once per emit.
  TaskDetailState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    TaskModel? task,
    bool? refreshing,
    bool? busy,
    bool closeScreen = false,
  }) => TaskDetailState(
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
