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

  /// True while a refresh is in flight; pull-to-refresh awaits it.
  final bool refreshing;

  /// Builds the initial state.
  const DashboardState({this.status = ScreenStatus.initial, this.response, this.summary, this.refreshing = false});

  /// Copies the state, resetting [response] unless a new one is passed so the
  /// same message can fire again on a later emit.
  DashboardState copyWith({
    ScreenStatus? status,
    Object? response = _absent,
    DashboardSummary? summary,
    bool? refreshing,
  }) => DashboardState(
    status: status ?? this.status,
    response: identical(response, _absent) ? null : response as ScreenResponse?,
    summary: summary ?? this.summary,
    refreshing: refreshing ?? this.refreshing,
  );

  @override
  List<Object?> get props => [status, response, summary, refreshing];
}
