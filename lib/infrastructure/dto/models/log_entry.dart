import '../../../domain/common/enums/log_kind.dart';
import 'user_ref.dart';

/// One line of a task's activity log.
class LogEntry {
  /// What happened.
  final LogKind kind;

  /// Who did it.
  final UserRef user;

  /// When it happened.
  final DateTime at;

  /// Values for the `{}` placeholders of the kind's sentence.
  final List<String> args;

  /// Builds a log entry from its parts.
  const LogEntry({required this.kind, required this.user, required this.at, this.args = const []});

  /// Parses the API object.
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    kind: LogKind.fromJson(json['kind']),
    user: UserRef.fromJson(json['user'] as Map<String, dynamic>),
    at: DateTime.parse('${json['at']}'),
    args: [for (final a in (json['args'] as List? ?? const [])) '$a'],
  );

  /// Serializes the entry.
  Map<String, dynamic> toJson() => {'kind': kind.name, 'user': user.toJson(), 'at': at.toIso8601String(), 'args': args};
}
