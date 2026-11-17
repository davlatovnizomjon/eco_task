part of 'bloc.dart';

/// Base of every action the dashboard can dispatch.
sealed class DashboardEvent {
  /// Allows the events to have const constructors.
  const DashboardEvent();
}

/// The dashboard opened — load the summary.
final class DashboardStarted extends DashboardEvent {
  /// Fires the first load.
  const DashboardStarted();
}

/// Pull-to-refresh — reload the summary.
final class DashboardRefreshed extends DashboardEvent {
  /// Reloads while keeping the current summary visible.
  const DashboardRefreshed();
}
