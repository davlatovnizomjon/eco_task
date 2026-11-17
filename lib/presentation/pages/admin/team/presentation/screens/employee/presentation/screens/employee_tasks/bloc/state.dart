part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything the employee-tasks screen renders itself from.
class EmployeeTasksState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Every loaded task of the member.
  final List<TaskModel> items;

  /// Selected tab: 0 all, 1 done, 2 failed.
  final int tab;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const EmployeeTasksState({
    this.status = ScreenStatus.initial,
    this.response,
    this.items = const [],
    this.tab = 0,
    this.refreshing = false,
  });

  /// Tasks of the selected tab.
  List<TaskModel> get visible => [
    for (final t in items)
      if (switch (tab) {
        1 => t.status == TaskStatus.done,
        2 => t.status == TaskStatus.fail,
        _ => true,
      })
        t,
  ];

  /// Copies the state, resetting [response] unless a new one is passed so it fires once.
  EmployeeTasksState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    List<TaskModel>? items,
    int? tab,
    bool? refreshing,
  }) => EmployeeTasksState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    items: items ?? this.items,
    tab: tab ?? this.tab,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, items, tab, refreshing];
}
