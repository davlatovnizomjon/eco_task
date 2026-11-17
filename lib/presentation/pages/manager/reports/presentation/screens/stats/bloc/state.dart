part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from "set it to null".
const _absent = Object();

/// Everything a statistics screen renders itself from.
class StatsState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Selected window length.
  final StatsPeriod period;

  /// Windows back from the current one (0 or negative).
  final int offset;

  /// Numbers of the selected window (cached or fresh); null while its first load runs or after it failed.
  final StatsReport? report;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// True while the downloadable report is being prepared.
  final bool exporting;

  /// Builds the initial state: the current month.
  const StatsState({
    this.status = ScreenStatus.initial,
    this.response,
    this.period = StatsPeriod.month,
    this.offset = 0,
    this.report,
    this.refreshing = false,
    this.exporting = false,
  });

  /// Copies the state, resetting [response] unless passed; [clearReport] drops the numbers of a left window.
  StatsState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    StatsPeriod? period,
    int? offset,
    StatsReport? report,
    bool clearReport = false,
    bool? refreshing,
    bool? exporting,
  }) => StatsState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    period: period ?? this.period,
    offset: offset ?? this.offset,
    report: clearReport ? null : (report ?? this.report),
    refreshing: refreshing ?? this.refreshing,
    exporting: exporting ?? this.exporting,
  );

  @override
  List<Object?> get props => [status, response, period, offset, report, refreshing, exporting];
}
