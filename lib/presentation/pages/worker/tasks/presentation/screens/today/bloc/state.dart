part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the "today's tasks" list renders itself from.
class TodayState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Tasks due today or overdue.
  final List<TaskModel> tasks;

  /// Selected chip: 0 all, 1 in progress, 2 new, 3 overdue.
  final int filter;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const TodayState({
    this.status = ScreenStatus.initial,
    this.response,
    this.tasks = const [],
    this.filter = 0,
    this.refreshing = false,
  });

  /// Tasks that pass the selected chip.
  List<TaskModel> get visible => switch (filter) {
    1 => [
      for (final t in tasks)
        if (t.status == TaskStatus.prog) t,
    ],
    2 => [
      for (final t in tasks)
        if (t.status == TaskStatus.fresh) t,
    ],
    3 => [
      for (final t in tasks)
        if (t.isOverdue) t,
    ],
    _ => tasks,
  };

  /// Tasks already finished.
  int get doneCount => tasks.where((t) => t.status == TaskStatus.done).length;

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  TodayState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    List<TaskModel>? tasks,
    int? filter,
    bool? refreshing,
  }) => TodayState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    tasks: tasks ?? this.tasks,
    filter: filter ?? this.filter,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, tasks, filter, refreshing];
}
