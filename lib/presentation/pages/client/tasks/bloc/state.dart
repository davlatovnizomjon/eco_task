part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the task list renders itself from.
class TasksState extends Equatable {
  /// Request lifecycle of the first page.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Active search, filters and sort.
  final TaskQuery query;

  /// Loaded rows (cached or fresh), pages appended in order.
  final List<TaskModel> items;

  /// Number of the last loaded page.
  final int page;

  /// Number of the last page the server has.
  final int lastPage;

  /// True while the next page is loading; shows the bottom spinner.
  final bool isLoadingMore;

  /// True while a refresh is in flight. Pull-to-refresh awaits THIS rather
  /// than `status`, which flips to success on the cached emit.
  final bool refreshing;

  /// Staff offered by the assignee filter; empty until it was opened once.
  final List<AppUser> staff;

  /// True while [staff] is being loaded.
  final bool staffLoading;

  /// Builds the initial, empty state.
  const TasksState({
    this.status = ScreenStatus.initial,
    this.response,
    this.query = const TaskQuery(),
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.refreshing = false,
    this.staff = const [],
    this.staffLoading = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  TasksState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    TaskQuery? query,
    List<TaskModel>? items,
    int? page,
    int? lastPage,
    bool? isLoadingMore,
    bool? refreshing,
    List<AppUser>? staff,
    bool? staffLoading,
  }) => TasksState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    query: query ?? this.query,
    items: items ?? this.items,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    refreshing: refreshing ?? this.refreshing,
    staff: staff ?? this.staff,
    staffLoading: staffLoading ?? this.staffLoading,
  );

  @override
  List<Object?> get props => [
    status,
    response,
    query.cacheKey,
    items,
    page,
    lastPage,
    isLoadingMore,
    refreshing,
    staff,
    staffLoading,
  ];
}
