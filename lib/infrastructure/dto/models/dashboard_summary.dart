import 'person_stat.dart';
import 'task_model.dart';

/// Everything the boss dashboard renders in one answer.
class DashboardSummary {
  /// Results waiting for review.
  final int inReview;

  /// Overdue open tasks.
  final int overdue;

  /// Expenses waiting for a decision.
  final int pendingExpenses;

  /// New tasks waiting for the admin's approval before work starts.
  final int pendingNew;

  /// Tasks created by clients that wait for the admin's approval.
  final int pendingClient;

  /// Open tasks due today or already late, soonest first.
  final List<TaskModel> dueToday;

  /// Per-worker counters of the boss's scope.
  final List<PersonStat> team;

  /// Builds the summary from its parts.
  const DashboardSummary({
    this.inReview = 0,
    this.overdue = 0,
    this.pendingExpenses = 0,
    this.pendingNew = 0,
    this.pendingClient = 0,
    this.dueToday = const [],
    this.team = const [],
  });

  /// Parses the API object.
  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    inReview: (json['inReview'] as num?)?.toInt() ?? 0,
    overdue: (json['overdue'] as num?)?.toInt() ?? 0,
    pendingExpenses: (json['pendingExpenses'] as num?)?.toInt() ?? 0,
    pendingNew: (json['pendingNew'] as num?)?.toInt() ?? 0,
    pendingClient: (json['pendingClient'] as num?)?.toInt() ?? 0,
    dueToday: [for (final t in (json['dueToday'] as List? ?? const [])) TaskModel.fromJson(t as Map<String, dynamic>)],
    team: [for (final p in (json['team'] as List? ?? const [])) PersonStat.fromJson(p as Map<String, dynamic>)],
  );
}
