part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the worker's task list renders itself from.
class MyTasksState extends Equatable {
  /// Request lifecycle of the first page.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Selected tab: 0 active, 1 history.
  final int tab;

  /// Loaded rows (cached or fresh), pages appended in order.
  final List<TaskModel> items;

  /// Number of the last loaded page.
  final int page;

  /// Number of the last page the server has.
  final int lastPage;

  /// True while the next page is loading; shows the bottom spinner.
  final bool isLoadingMore;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state on [tab].
  const MyTasksState({
    this.status = ScreenStatus.initial,
    this.response,
    this.tab = 0,
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.refreshing = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  MyTasksState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    int? tab,
    List<TaskModel>? items,
    int? page,
    int? lastPage,
    bool? isLoadingMore,
    bool? refreshing,
  }) => MyTasksState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    tab: tab ?? this.tab,
    items: items ?? this.items,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, tab, items, page, lastPage, isLoadingMore, refreshing];
}
