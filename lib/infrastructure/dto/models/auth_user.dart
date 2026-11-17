import 'app_user.dart';

/// The signed-in session: the token pair plus the account it belongs to.
class AuthUser {
  /// Short-lived bearer token sent with every request.
  final String accessToken;

  /// Long-lived single-use token traded for a new pair when the access token expires; empty for the mock backend and
  /// for sessions saved before refresh existed.
  final String refreshToken;

  /// The signed-in account.
  final AppUser user;

  /// Builds a session from its parts.
  const AuthUser({required this.accessToken, this.refreshToken = '', required this.user});

  /// Parses the `auth/login` answer (and the persisted session).
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    accessToken: '${json['token']}',
    refreshToken: '${json['refresh'] ?? ''}',
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  /// Copy with a new token pair (after a refresh or a password change).
  AuthUser withTokens({required String accessToken, required String refreshToken}) =>
      AuthUser(accessToken: accessToken, refreshToken: refreshToken, user: user);

  /// Copy for the same tokens with an updated account.
  AuthUser withUser(AppUser updated) => AuthUser(accessToken: accessToken, refreshToken: refreshToken, user: updated);

  /// Serializes the session for secure storage.
  Map<String, dynamic> toJson() => {'token': accessToken, 'refresh': refreshToken, 'user': user.toJson()};
}
