part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the review queue renders itself from.
class ReviewState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Selected tab: 0 results, 1 expenses.
  final int tab;

  /// Tasks whose results wait for a decision (cached or fresh).
  final List<TaskModel> results;

  /// Expenses waiting for a decision (cached or fresh).
  final List<ExpenseEntry> pending;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// True while an approve/return request is running.
  final bool busy;

  /// Builds the initial state.
  const ReviewState({
    this.status = ScreenStatus.initial,
    this.response,
    this.tab = 0,
    this.results = const [],
    this.pending = const [],
    this.refreshing = false,
    this.busy = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  ReviewState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    int? tab,
    List<TaskModel>? results,
    List<ExpenseEntry>? pending,
    bool? refreshing,
    bool? busy,
  }) => ReviewState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    tab: tab ?? this.tab,
    results: results ?? this.results,
    pending: pending ?? this.pending,
    refreshing: refreshing ?? this.refreshing,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [status, response, tab, results, pending, refreshing, busy];
}
