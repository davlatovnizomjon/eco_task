import 'package:flutter/foundation.dart';

import 'package:eco_task/domain/common/enums/user_role.dart';

import '../common/api_links.dart';
import '../common/api_cache.dart';
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

  /// Drops the session locally. Called by the user on sign-out and by
  /// `DioClient` whenever the backend answers 401.
  Future<void> clearSession() async {
    await _store.clear();
    ApiCache.invalidate();
    user.value = null;
  }

  /// Releases the notifier when the app root is torn down.
  void dispose() => user.dispose();
}
