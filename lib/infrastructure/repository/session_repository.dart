import 'package:flutter/foundation.dart';

import 'package:eco_task/domain/common/enums/user_role.dart';

import '../common/api_links.dart';
import '../common/api_cache.dart';
import '../dto/models/app_user.dart';
import '../dto/models/app_user.dart';
import '../dto/models/auth_user.dart';
import '../services/secure_store.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// Owns the signed-in identity for the whole app.
///
/// It is the ONLY thing that mutates [user]; screens and the router listen to
/// that notifier instead of asking a bloc whether somebody is signed in.
/// Provided once at the root of the widget tree.
class SessionRepository {
  /// Secure storage the session is persisted in and restored from.
  final SecureStore _store;

  /// Current session, or null while signed out. Every listener rebuilds when
  /// it changes, which is how the app flips between sign-in and the home.
  final ValueNotifier<AuthUser?> user;

  /// Runs just before the token is revoked on sign-out (the push service forgets this device's token here).
  Future<void> Function()? beforeSignOut;

  /// Wraps [store] and seeds [user] with whatever was already persisted.
  SessionRepository(SecureStore store) : _store = store, user = ValueNotifier(store.user);

  /// True while nobody is signed in; drives the router's redirect.
  bool get isGuest => user.value == null;

  /// Bearer token for the `Authorization` header; empty when signed out.
  String get token => _store.token;

  /// Role of the signed-in account, or null while signed out.
  UserRole? get role => user.value?.user.role;

  /// Signs the user in, persists the session, then publishes it. Persisting
  /// is awaited first so the next request already carries the token. Throws
  /// the typed failure `dioClient` mapped (e.g. wrong credentials).
  Future<void> login({required String login, required String password}) async {
    final response = await dioClient.post(ApiLinks.authLogin, data: {'login': login, 'password': password});
    final parsed = AuthUser.fromJson(response.data as Map<String, dynamic>);
    await _store.saveUser(parsed);
    ApiCache.invalidate();
    user.value = parsed;
  }

  /// Saves the signed-in person's [name] and, when given, [login]; the stored session and the `user` notifier follow.
  Future<void> updateAccount({required String name, String? login}) async {
    final response = await dioClient.request(
      ApiLinks.account,
      method: 'PATCH',
      data: {'name': name, if (login != null) 'login': login},
    );
    final updated = AppUser.fromJson(response.data as Map<String, dynamic>);
    final next = user.value!.withUser(updated);
    await _store.saveUser(next);
    user.value = next;
  }

  /// Changes the password; the backend revokes old sessions, so the fresh token pair it returns replaces the stored one.
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    final response = await dioClient.post(
      ApiLinks.accountPassword,
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    final data = response.data as Map;
    final next = user.value!.withTokens(accessToken: '${data['token']}', refreshToken: '${data['refresh'] ?? ''}');
    await _store.saveUser(next);
    user.value = next;
  }

  /// True when the session holds a refresh token that can renew an expired access token.
  bool get canRefresh => (user.value?.refreshToken ?? '').isNotEmpty;

  /// Refresh in flight; concurrent callers share it because every refresh token works exactly once.
  Future<void>? _refreshing;

  /// Trades the refresh token for a new token pair and stores it. Concurrent calls share one request. Throws the
  /// typed failure `dioClient` mapped; a 401 there has already cleared the session.
  Future<void> refreshTokens() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  /// Performs one refresh round trip.
  Future<void> _refresh() async {
    final current = user.value!;
    final response = await dioClient.post(ApiLinks.authRefresh, data: {'refresh': current.refreshToken});
    final data = response.data as Map;
    final next = current.withTokens(accessToken: '${data['token']}', refreshToken: '${data['refresh']}');
    await _store.saveUser(next);
    user.value = next;
  }

  /// Revokes the token on the backend (best-effort), then drops the session
  /// locally. Also called by `DioClient` on a 401 — in that case the token is
  /// already invalid, so the backend call is skipped.
  Future<void> clearSession({bool revokeRemotely = true}) async {
    if (revokeRemotely && !isGuest) {
      try {
        await beforeSignOut?.call();
        await dioClient.post(ApiLinks.authLogout);
      } catch (_) {
        // Network unavailable — proceed with local clear anyway.
      }
    }
    await _store.clear();
    ApiCache.invalidate();
    user.value = null;
  }

  /// Releases the notifier when the app root is torn down.
  void dispose() => user.dispose();
}
