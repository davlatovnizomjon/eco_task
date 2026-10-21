/// Money totals and filter counters of the expenses screen.
class ExpenseTotals {
  /// Sum of everything workers entered.
  final int entered;

  /// Sum of approved amounts.
  final int approved;

  /// Sum of rejected entries.
  final int rejected;

  /// Sum already paid out to workers (expenses and rewards).
  final int paidOut;

  /// Entries per filter key: `pending`, `approved`, `rejected`, `paid`.
  final Map<String, int> counts;

  /// Builds totals from their parts.
  const ExpenseTotals({
    this.entered = 0,
    this.approved = 0,
    this.rejected = 0,
    this.paidOut = 0,
    this.counts = const {},
  });

  /// Parses the API object.
  factory ExpenseTotals.fromJson(Map<String, dynamic> json) => ExpenseTotals(
    entered: (json['entered'] as num?)?.toInt() ?? 0,
    approved: (json['approved'] as num?)?.toInt() ?? 0,
    rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    paidOut: (json['paidOut'] as num?)?.toInt() ?? 0,
    counts: {for (final e in ((json['counts'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num).toInt()},
  );
}
