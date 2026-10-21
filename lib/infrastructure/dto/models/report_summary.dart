import '../../../domain/common/enums/task_status.dart';
import 'person_stat.dart';

/// Aggregated numbers of the reports, status and team-progress screens.
class ReportSummary {
  /// Task count per status.
  final Map<TaskStatus, int> counts;

  /// Open tasks that are overdue.
  final int overdue;

  /// Tasks delivered after their deadline.
  final int lateDelivered;

  /// Completed tasks per week, oldest first.
  final List<int> weekly;

  /// Sum of rewards of approved tasks.
  final int rewards;

  /// Sum of approved expenses.
  final int expenses;

  /// Sum paid out to workers.
  final int paid;

  /// Per-worker counters.
  final List<PersonStat> people;

  /// Builds the summary from its parts.
  const ReportSummary({
    this.counts = const {},
    this.overdue = 0,
    this.lateDelivered = 0,
    this.weekly = const [],
    this.rewards = 0,
    this.expenses = 0,
    this.paid = 0,
    this.people = const [],
  });

  /// Parses the API object.
  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    counts: {
      for (final e in ((json['counts'] as Map?) ?? const {}).entries)
        TaskStatus.fromJson(e.key): (e.value as num).toInt(),
    },
    overdue: (json['overdue'] as num?)?.toInt() ?? 0,
    lateDelivered: (json['lateDelivered'] as num?)?.toInt() ?? 0,
    weekly: [for (final w in (json['weekly'] as List? ?? const [])) (w as num).toInt()],
    rewards: (json['rewards'] as num?)?.toInt() ?? 0,
    expenses: (json['expenses'] as num?)?.toInt() ?? 0,
    paid: (json['paid'] as num?)?.toInt() ?? 0,
    people: [for (final p in (json['people'] as List? ?? const [])) PersonStat.fromJson(p as Map<String, dynamic>)],
  );

  /// Count of [status], 0 when absent.
  int countOf(TaskStatus status) => counts[status] ?? 0;

  /// Total number of tasks.
  int get total => counts.values.fold(0, (sum, n) => sum + n);
}
