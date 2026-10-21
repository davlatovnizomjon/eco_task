part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the team directory renders itself from.
class TeamState extends Equatable {
  /// Request lifecycle of the first page.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// True while the clients tab is selected, false for staff.
  final bool clients;

  /// Current search text.
  final String search;

  /// Loaded rows (cached or fresh), pages appended in order.
  final List<AppUser> items;

  /// Number of the last loaded page.
  final int page;

  /// Number of the last page the server has.
  final int lastPage;

  /// True while the next page is loading; shows the bottom spinner.
  final bool isLoadingMore;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state on the staff tab.
  const TeamState({
    this.status = ScreenStatus.initial,
    this.response,
    this.clients = false,
    this.search = '',
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.isLoadingMore = false,
    this.refreshing = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  TeamState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    bool? clients,
    String? search,
    List<AppUser>? items,
    int? page,
    int? lastPage,
    bool? isLoadingMore,
    bool? refreshing,
  }) => TeamState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    clients: clients ?? this.clients,
    search: search ?? this.search,
    items: items ?? this.items,
    page: page ?? this.page,
    lastPage: lastPage ?? this.lastPage,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, clients, search, items, page, lastPage, isLoadingMore, refreshing];
}
