import 'user_ref.dart';

/// One person row of a statistics screen: a client, an employee or a manager with two numbers whose meaning
/// depends on the screen (clients: tasks; staff: on-time percent, done; managers: created, revenue).
class StatsPerson {
  /// Who the row is about.
  final UserRef user;

  /// True when a client is an organization, false for a private person.
  final bool isOrg;

  /// Day a client was added; null for staff and managers.
  final DateTime? date;

  /// First number (clients: tasks; staff: on-time percent; managers: tasks created).
  final num a;

  /// Second number (staff: tasks done; managers: revenue).
  final num b;

  /// Builds a row from its parts.
  const StatsPerson({required this.user, this.isOrg = false, this.date, this.a = 0, this.b = 0});

  /// Parses one API row.
  factory StatsPerson.fromJson(Map<String, dynamic> json) => StatsPerson(
    user: UserRef.fromJson(json['user'] as Map<String, dynamic>),
    isOrg: json['isOrg'] as bool? ?? false,
    date: json['date'] == null ? null : DateTime.parse('${json['date']}'),
    a: json['a'] as num? ?? 0,
    b: json['b'] as num? ?? 0,
  );
}

/// Numbers of one statistics screen for one period. The same shape serves all six screens; which fields are
/// filled depends on the kind (see the field comments).
class StatsReport {
  /// Headline number: revenue, task count, new clients or head count.
  final num total;

  /// Change against the previous period: a percent, or a head count for staff; null when not compared.
  final num? delta;

  /// Headline number of the previous period (managers: shown as "last period N").
  final num previous;

  /// First tile under the headline (finance: done tasks; mine: done; clients: all clients; staff: done; managers:
  /// created).
  final num a;

  /// Second tile under the headline (finance: average price; mine: revenue; clients: organizations; staff:
  /// on-time percent; managers: revenue).
  final num b;

  /// Task counts by outcome — done, in progress, new, canceled (tasks screen only).
  final List<int> split;

  /// Bar chart values, one per day / week / month of the period.
  final List<num> bars;

  /// Planned revenue of the period (finance only).
  final num plan;

  /// Fact rows, positional per kind — finance: paid count, paid sum, pending count, pending sum, canceled count,
  /// canceled sum; tasks: on-time percent, overdue count, average days; mine: on-time percent, overdue count, new
  /// clients.
  final List<num> facts;

  /// People of the period (new clients, top employees, managers).
  final List<StatsPerson> people;

  /// Every client regardless of the period (clients screen, "all" tab).
  final List<StatsPerson> everyone;

  /// Builds a report from its parts.
  const StatsReport({
    this.total = 0,
    this.delta,
    this.previous = 0,
    this.a = 0,
    this.b = 0,
    this.split = const [],
    this.bars = const [],
    this.plan = 0,
    this.facts = const [],
    this.people = const [],
    this.everyone = const [],
  });

  /// True when the period has nothing to show at all.
  bool get isEmpty => total == 0 && people.isEmpty && everyone.isEmpty && bars.every((v) => v == 0);

  /// Parses the API object.
  factory StatsReport.fromJson(Map<String, dynamic> json) => StatsReport(
    total: json['total'] as num? ?? 0,
    delta: json['delta'] as num?,
    previous: json['previous'] as num? ?? 0,
    a: json['a'] as num? ?? 0,
    b: json['b'] as num? ?? 0,
    split: [for (final v in (json['split'] as List? ?? const [])) (v as num).toInt()],
    bars: [for (final v in (json['bars'] as List? ?? const [])) v as num],
    plan: json['plan'] as num? ?? 0,
    facts: [for (final v in (json['facts'] as List? ?? const [])) v as num],
    people: [for (final p in (json['people'] as List? ?? const [])) StatsPerson.fromJson(p as Map<String, dynamic>)],
    everyone: [
      for (final p in (json['everyone'] as List? ?? const [])) StatsPerson.fromJson(p as Map<String, dynamic>),
    ],
  );
}
