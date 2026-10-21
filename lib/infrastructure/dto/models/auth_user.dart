import 'app_user.dart';

/// The signed-in session: the bearer token plus the account it belongs to.
class AuthUser {
  /// Bearer token sent with every request.
  final String accessToken;

  /// The signed-in account.
  final AppUser user;

  /// Builds a session from its parts.
  const AuthUser({required this.accessToken, required this.user});

  /// Parses the `auth/login` answer (and the persisted session).
  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      AuthUser(accessToken: '${json['token']}', user: AppUser.fromJson(json['user'] as Map<String, dynamic>));

  /// Serializes the session for secure storage.
  Map<String, dynamic> toJson() => {'token': accessToken, 'user': user.toJson()};
}
