import '../../../domain/common/enums/user_role.dart';

/// What the "open an account" form sends.
class NewAccount {
  /// Sign-in login; becomes the account id.
  final String login;

  /// Full display name.
  final String name;

  /// Phone number in API form (`+998...`).
  final String phone;

  /// Account kind.
  final UserRole role;

  /// Team (staff) or district/address (clients).
  final String team;

  /// Temporary password the boss hands over.
  final String password;

  /// Builds the payload from its parts.
  const NewAccount({
    required this.login,
    required this.name,
    required this.phone,
    required this.role,
    required this.team,
    required this.password,
  });

  /// Request body of `POST users`.
  Map<String, dynamic> toJson() => {
    'id': login,
    'name': name,
    'phone': phone,
    'role': role.name,
    'team': team,
    'password': password,
  };
}
