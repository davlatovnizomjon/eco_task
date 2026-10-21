import '../../../domain/common/enums/user_role.dart';
import 'user_ref.dart';

/// A person of the company or a client account, as the API returns it.
class AppUser {
  /// Stable id; also the sign-in login in the demo backend.
  final String id;

  /// Full display name.
  final String name;

  /// Raw phone number as stored by the backend; show it with `PhoneFormatter`.
  final String phone;

  /// Team name for staff, district for clients.
  final String team;

  /// Account kind; decides the home tabs and permissions.
  final UserRole role;

  /// Index into the avatar color palette.
  final int color;

  /// Open tasks (staff) or open requests (clients), filled by directory lists.
  final int activeCount;

  /// Builds a user from its parts.
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.phone = '',
    this.team = '',
    this.color = 0,
    this.activeCount = 0,
  });

  /// Parses the API object.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: '${json['id']}',
    name: '${json['name']}',
    role: UserRole.fromJson(json['role']),
    phone: '${json['phone'] ?? ''}',
    team: '${json['team'] ?? ''}',
    color: (json['color'] as num?)?.toInt() ?? 0,
    activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
  );

  /// Serializes the user (also used to persist the session).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'phone': phone,
    'team': team,
    'color': color,
    'activeCount': activeCount,
  };

  /// Copy carrying the directory counter [count].
  AppUser withActiveCount(int count) =>
      AppUser(id: id, name: name, role: role, phone: phone, team: team, color: color, activeCount: count);

  /// First letters of the first two words of [name], upper-cased.
  String get initials => name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

  /// First word of [name], used in greetings and compact rows.
  String get firstName => name.split(' ').first;

  /// Lightweight reference to this account.
  UserRef get ref => UserRef(id: id, name: name, color: color);
}
