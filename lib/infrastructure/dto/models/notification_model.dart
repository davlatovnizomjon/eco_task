import '../../../domain/common/enums/notification_kind.dart';

/// One inbox entry; its texts are built from [kind] and the two arg lists.
class NotificationModel {
  /// Unique id.
  final String id;

  /// Id of the account the entry belongs to.
  final String userId;

  /// Type; picks icon, color and texts.
  final NotificationKind kind;

  /// Values for the headline's `{}` placeholders.
  final List<String> titleArgs;

  /// Values for the body's `{}` placeholders.
  final List<String> bodyArgs;

  /// When it was created.
  final DateTime at;

  /// True once the user opened or dismissed it.
  final bool isRead;

  /// Builds an entry from its parts.
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.kind,
    required this.at,
    this.titleArgs = const [],
    this.bodyArgs = const [],
    this.isRead = false,
  });

  /// Parses the API object.
  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: '${json['id']}',
    userId: '${json['userId']}',
    kind: NotificationKind.fromJson(json['kind']),
    at: DateTime.parse('${json['at']}'),
    titleArgs: [for (final a in (json['titleArgs'] as List? ?? const [])) '$a'],
    bodyArgs: [for (final a in (json['bodyArgs'] as List? ?? const [])) '$a'],
    isRead: json['isRead'] as bool? ?? false,
  );

  /// Serializes the entry.
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'kind': kind.name,
    'at': at.toIso8601String(),
    'titleArgs': titleArgs,
    'bodyArgs': bodyArgs,
    'isRead': isRead,
  };

  /// Copy marked as read.
  NotificationModel asRead() => NotificationModel(
    id: id,
    userId: userId,
    kind: kind,
    at: at,
    titleArgs: titleArgs,
    bodyArgs: bodyArgs,
    isRead: true,
  );
}
