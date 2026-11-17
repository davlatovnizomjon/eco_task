import '../../../domain/common/enums/user_role.dart';

/// Lightweight reference to a person embedded in tasks, comments, expenses and
/// requests, so a screen can show a name and avatar without a directory lookup.
class UserRef {
  /// Id of the referenced account.
  final String id;

  /// Full display name.
  final String name;

  /// Index into the avatar color palette.
  final int color;

  /// Account role when the source carries it (chat members); null otherwise.
  final UserRole? role;

  /// Picture URL; empty when the person has none (initials are drawn instead).
  final String avatarUrl;

  /// Builds a reference from its parts.
  const UserRef({required this.id, required this.name, this.color = 0, this.role, this.avatarUrl = ''});

  /// Parses the API object.
  factory UserRef.fromJson(Map<String, dynamic> json) => UserRef(
    id: '${json['id']}',
    name: '${json['name']}',
    color: (json['color'] as num?)?.toInt() ?? 0,
    role: json['role'] == null ? null : UserRole.fromJson(json['role']),
    avatarUrl: '${json['avatarUrl'] ?? ''}',
  );

  /// Parses a backend `UserBrief` (`full_name`, `username`, numeric id); the avatar color is derived from the id.
  factory UserRef.fromBackend(Map<String, dynamic> json) {
    final full = '${json['full_name'] ?? ''}'.trim();
    return UserRef(
      id: '${json['id']}',
      name: full.isNotEmpty ? full : '${json['username'] ?? json['id']}',
      color: (json['color'] as num?)?.toInt() ?? (int.tryParse('${json['id']}') ?? 0) % 8,
      role: json['role'] == null ? null : UserRole.fromJson(json['role']),
      avatarUrl: '${json['avatar_url'] ?? ''}',
    );
  }

  /// Serializes the reference.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    if (role != null) 'role': role!.name,
    'avatarUrl': avatarUrl,
  };

  /// First letters of the first two words of [name], upper-cased.
  String get initials => name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

  /// First word of [name], used in greetings and compact rows.
  String get firstName => name.split(' ').first;
}
