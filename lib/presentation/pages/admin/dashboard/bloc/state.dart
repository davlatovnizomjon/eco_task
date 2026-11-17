part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the dashboard renders itself from.
class DashboardState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// The loaded numbers (cached or fresh); null until the first answer.
  final DashboardSummary? summary;

  /// This week's report (weekly progress card); null until loaded.
  final ReportSummary? week;

  /// The admin's own open tasks, nearest deadline first.
  final List<TaskModel> mine;

  /// Number of staff accounts.
  final int staffTotal;

  /// Number of client accounts.
  final int clientTotal;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const DashboardState({
    this.status = ScreenStatus.initial,
    this.response,
    this.summary,
    this.week,
    this.mine = const [],
    this.staffTotal = 0,
    this.clientTotal = 0,
    this.refreshing = false,
  });

  /// True for a brand-new company — nobody but the admin, no clients and no tasks: the dashboard shows the first steps.
  bool get isBlank =>
      summary != null &&
      staffTotal <= 1 &&
      clientTotal == 0 &&
      mine.isEmpty &&
      summary!.dueToday.isEmpty &&
      (week?.total ?? 0) == 0;

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  DashboardState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    DashboardSummary? summary,
    ReportSummary? week,
    List<TaskModel>? mine,
    int? staffTotal,
    int? clientTotal,
    bool? refreshing,
  }) => DashboardState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    summary: summary ?? this.summary,
    week: week ?? this.week,
    mine: mine ?? this.mine,
    staffTotal: staffTotal ?? this.staffTotal,
    clientTotal: clientTotal ?? this.clientTotal,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, summary, week, mine, staffTotal, clientTotal, refreshing];
}
