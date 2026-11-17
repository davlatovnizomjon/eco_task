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

  /// True for a client that is an organization (a private person otherwise).
  final bool isOrg;

  /// Contact person of an organization client; empty otherwise.
  final String contactPerson;

  /// Free note about a client; empty when none.
  final String note;

  /// Account kind; decides the home tabs and permissions.
  final UserRole role;

  /// Index into the avatar color palette.
  final int color;

  /// Open tasks (staff) or open requests (clients), filled by directory lists.
  final int activeCount;

  /// Picture URL of the account; empty when none is set (initials are drawn instead).
  final String avatarUrl;

  /// Builds a user from its parts.
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.phone = '',
    this.team = '',
    this.isOrg = false,
    this.contactPerson = '',
    this.note = '',
    this.color = 0,
    this.activeCount = 0,
    this.avatarUrl = '',
  });

  /// Parses the API object.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: '${json['id']}',
    name: '${json['name']}',
    role: UserRole.fromJson(json['role']),
    phone: '${json['phone'] ?? ''}',
    team: '${json['team'] ?? ''}',
    isOrg: json['isOrg'] as bool? ?? false,
    contactPerson: '${json['contactPerson'] ?? ''}',
    note: '${json['note'] ?? ''}',
    color: (json['color'] as num?)?.toInt() ?? 0,
    activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
    avatarUrl: '${json['avatarUrl'] ?? ''}',
  );

  /// Serializes the user (also used to persist the session).
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.name,
    'phone': phone,
    'team': team,
    'isOrg': isOrg,
    'contactPerson': contactPerson,
    'note': note,
    'color': color,
    'activeCount': activeCount,
    'avatarUrl': avatarUrl,
  };

  /// Copy carrying the directory counter [count].
  AppUser withActiveCount(int count) => AppUser(
    id: id,
    name: name,
    role: role,
    phone: phone,
    team: team,
    isOrg: isOrg,
    contactPerson: contactPerson,
    note: note,
    color: color,
    activeCount: count,
    avatarUrl: avatarUrl,
  );

  /// Copy with the editable profile fields replaced.
  AppUser withProfile({String? name, String? phone, String? team, bool? isOrg, String? contactPerson, String? note}) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        role: role,
        phone: phone ?? this.phone,
        team: team ?? this.team,
        isOrg: isOrg ?? this.isOrg,
        contactPerson: contactPerson ?? this.contactPerson,
        note: note ?? this.note,
        color: color,
        activeCount: activeCount,
        avatarUrl: avatarUrl,
      );

  /// First letters of the first two words of [name], upper-cased.
  String get initials => name.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

  /// First word of [name], used in greetings and compact rows.
  String get firstName => name.split(' ').first;

  /// Lightweight reference to this account.
  UserRef get ref => UserRef(id: id, name: name, color: color, role: role, avatarUrl: avatarUrl);
}
