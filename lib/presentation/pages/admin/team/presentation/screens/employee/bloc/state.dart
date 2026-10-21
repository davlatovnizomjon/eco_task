part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the employee profile renders itself from.
class EmployeeState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The employee's account; null until the first answer.
  final AppUser? user;

  /// Every task the employee takes part in (cached or fresh).
  final List<TaskModel> items;

  /// Selected tab: 0 active, 1 history.
  final int tab;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const EmployeeState({
    this.status = ScreenStatus.initial,
    this.response,
    this.user,
    this.items = const [],
    this.tab = 0,
    this.refreshing = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  EmployeeState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    AppUser? user,
    List<TaskModel>? items,
    int? tab,
    bool? refreshing,
  }) => EmployeeState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    user: user ?? this.user,
    items: items ?? this.items,
    tab: tab ?? this.tab,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, user, items, tab, refreshing];
}
