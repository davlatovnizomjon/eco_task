import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../dto/models/auth_user.dart';

/// Keychain/Keystore-backed store for the signed-in session.
///
/// Secure storage is async-only, but the HTTP client builds its headers
/// synchronously, so the loaded value is mirrored in memory and kept in sync
/// on every write. Only [SessionRepository] talks to this class.
class SecureStore {
  /// Platform secure storage; the only place the raw plugin is touched.
  final FlutterSecureStorage _storage;

  /// In-memory mirror of the persisted session, readable synchronously.
  AuthUser? _user;

  /// Wraps an already-created [FlutterSecureStorage].
  SecureStore(this._storage);

  /// Key the whole session object is stored under, as JSON.
  static const _userKey = 'eco_tasks_session';

  /// Opens the store and loads the persisted session into memory.
  /// Must be awaited in `main()` before the first request is issued.
  static Future<SecureStore> create() async {
    final store = SecureStore(const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true)));
    await store._restore();
    return store;
  }

  /// The persisted session, or null while nobody is signed in.
  AuthUser? get user => _user;

  /// Bearer token for the `Authorization` header; empty when signed out.
  String get token => _user?.accessToken ?? '';

  /// Persists [user] and updates the in-memory mirror.
  Future<void> saveUser(AuthUser user) async {
    _user = user;
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } on PlatformException {
      // Keychain/Keystore unavailable (e.g. an unsigned simulator build): the session lives in memory only.
    }
  }

  /// Drops the session from memory and from the device.
  Future<void> clear() async {
    _user = null;
    try {
      await _storage.delete(key: _userKey);
    } on PlatformException {
      // Nothing persisted when the secure storage is unavailable.
    }
  }

  /// Reads the persisted session into [_user]; a corrupt entry is discarded
  /// rather than crashing the app at startup.
  Future<void> _restore() async {
    final String? raw;
    try {
      raw = await _storage.read(key: _userKey);
    } on PlatformException {
      // Secure storage is unavailable (missing keychain entitlement): start signed out instead of crashing.
      return;
    }
    if (raw == null || raw.isEmpty) return;
    try {
      _user = AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear();
    }
  }
}
