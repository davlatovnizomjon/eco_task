part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the expenses screen renders itself from.
class ExpensesState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Selected filter tab (index into `ExpensesBloc.filters`).
  final int filter;

  /// Rows of the selected tab (cached or fresh), pages appended in order.
  final List<ExpenseEntry> items;

  /// Money totals and per-tab counters; null until the first answer.
  final ExpenseTotals? totals;

  /// Completed tasks with a reward, for the payouts section.
  final List<TaskModel> rewards;

  /// Number of the last loaded page.
  final int page;

  /// Number of the last page the server has.
  final int lastPage;

  /// True while the next page is loading; shows the bottom spinner.
  final bool isLoadingMore;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const ExpensesState({
    this.status = ScreenStatus.initial,
    this.response,
    this.filter = 0,
    this.items = const [],
    this.totals,
    this.rewards = const [],
    this.page = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.refreshing = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  ExpensesState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    int? filter,
    List<ExpenseEntry>? items,
    ExpenseTotals? totals,
    List<TaskModel>? rewards,
    int? page,
    int? lastPage,
    bool? isLoadingMore,
    bool? refreshing,
  }) => ExpensesState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    filter: filter ?? this.filter,
    items: items ?? this.items,
    totals: totals ?? this.totals,
    rewards: rewards ?? this.rewards,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    filter,
    items,
    totals,
    rewards,
    page,
    lastPage,
    isLoadingMore,
    refreshing,
  ];
}
