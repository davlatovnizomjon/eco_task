part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the calendar renders itself from.
class CalendarState extends Equatable {
  /// Request lifecycle of the month load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Any day of the visible month.
  final DateTime month;

  /// The selected day.
  final DateTime selected;

  /// Tasks whose deadline falls into the visible month (cached or fresh).
  final List<TaskModel> tasks;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state for [month] and [selected].
  const CalendarState({
    required this.month,
    required this.selected,
    this.status = ScreenStatus.initial,
    this.response,
    this.tasks = const [],
    this.refreshing = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  CalendarState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    DateTime? month,
    DateTime? selected,
    List<TaskModel>? tasks,
    bool? refreshing,
  }) => CalendarState(
    month: month ?? this.month,
    selected: selected ?? this.selected,
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    tasks: tasks ?? this.tasks,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, month, selected, tasks, refreshing];
}
