import 'app_user.dart';

/// A worker's task counters, shown in team progress blocks.
class PersonStat {
  /// The worker.
  final AppUser user;

  /// Tasks the worker completed.
  final int done;

  /// All tasks the worker took part in.
  final int total;

  /// Days the worst overdue task is late; 0 when nothing is overdue.
  final int lateDays;

  /// Completed tasks delivered by their deadline.
  final int onTime;

  /// Builds the counters from their parts.
  const PersonStat({required this.user, this.done = 0, this.total = 0, this.lateDays = 0, this.onTime = 0});

  /// Parses the API object.
  factory PersonStat.fromJson(Map<String, dynamic> json) => PersonStat(
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    done: (json['done'] as num?)?.toInt() ?? 0,
    total: (json['total'] as num?)?.toInt() ?? 0,
    lateDays: (json['lateDays'] as num?)?.toInt() ?? 0,
    onTime: (json['onTime'] as num?)?.toInt() ?? 0,
  );

  /// Serializes the counters.
  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'done': done,
    'total': total,
    'lateDays': lateDays,
    'onTime': onTime,
  };

  /// True when at least one task of this worker is overdue.
  bool get hasLate => lateDays > 0;
}
