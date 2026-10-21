import '../../../domain/common/enums/user_role.dart';

/// Role and permission switches of one staff member.
class PermissionsModel {
  /// Id of the staff member.
  final String userId;

  /// Current role.
  final UserRole role;

  /// Switch values by key: `create`, `reward`, `approve`, `editOthers`, `approveExpense`, `viewPayments`.
  final Map<String, bool> flags;

  /// Builds the permissions from their parts.
  const PermissionsModel({required this.userId, required this.role, this.flags = const {}});

  /// Parses the API object.
  factory PermissionsModel.fromJson(Map<String, dynamic> json) => PermissionsModel(
    userId: '${json['userId']}',
    role: UserRole.fromJson(json['role']),
    flags: {for (final e in ((json['flags'] as Map?) ?? const {}).entries) '${e.key}': e.value == true},
  );

  /// Serializes the permissions.
  Map<String, dynamic> toJson() => {'userId': userId, 'role': role.name, 'flags': flags};

  /// Copy with a new [role] or [flags].
  PermissionsModel copyWith({UserRole? role, Map<String, bool>? flags}) =>
      PermissionsModel(userId: userId, role: role ?? this.role, flags: flags ?? this.flags);
}
