part of 'bloc.dart';

/// Sentinel that lets `copyWith` tell "leave this field alone" apart from
/// "set it to null".
const _absent = Object();

/// Everything the screen renders itself from.
class TaskStatusState extends Equatable {
  /// Request lifecycle of the load.
  final ScreenStatus status;

  /// One-shot feedback for the listener to present; reset by the next emit.
  final ScreenResponse? response;

  /// Selected period.
  final ReportPeriod period;

  /// The loaded numbers (cached or fresh); null until the first answer.
  final ReportSummary? summary;

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state on the month period.
  const TaskStatusState({
    this.status = ScreenStatus.initial,
    this.response,
    this.period = ReportPeriod.month,
    this.summary,
    this.refreshing = false,
  });

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  TaskStatusState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    ReportPeriod? period,
    ReportSummary? summary,
    bool? refreshing,
  }) => TaskStatusState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    period: period ?? this.period,
    summary: summary ?? this.summary,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, period, summary, refreshing];
}
