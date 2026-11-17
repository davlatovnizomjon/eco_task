import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../common/api_links.dart';
import '../repository/session_repository.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// Push notifications through Firebase Cloud Messaging.
///
/// Push is optional: when Firebase is not configured for the platform (no `GoogleService-Info.plist` /
/// `google-services.json`) or the user denies the permission, [start] quietly does nothing and the app keeps working
/// from the in-app inbox. The device token is registered with the backend while somebody is signed in and
/// forgotten again on sign-out, so a shared phone never receives the previous person's pushes.
class PushService {
  /// Session whose sign-in/sign-out drives token registration.
  final SessionRepository session;

  /// Called with the push payload when the user taps a notification (opens the matching screen).
  final void Function(Map<String, String> data) onOpen;

  /// Called when a push arrives while the app is open (refreshes the unread badge).
  final VoidCallback onForeground;

  /// Language tag sent along with the token.
  final String Function() language;

  /// Builds the service; call [start] once after the app is running.
  PushService({required this.session, required this.onOpen, required this.onForeground, required this.language});

  /// Token last registered with the backend, kept for the sign-out call.
  String? _token;

  /// True once Firebase initialised and the listeners are attached.
  bool _ready = false;

  /// Initialises Firebase, asks for permission and starts following the session and the token.
  Future<void> start() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      _ready = true;
      messaging.onTokenRefresh.listen((token) {
        _token = token;
        unawaited(_register());
      });
      FirebaseMessaging.onMessage.listen((_) => onForeground());
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(_payload(m)));
      final launch = await messaging.getInitialMessage();
      if (launch != null) onOpen(_payload(launch));
      session.user.addListener(() => unawaited(_register()));
      await _register();
    } catch (e) {
      debugPrint('Push disabled: $e');
    }
  }

  /// Registers the current token for the signed-in user (no-op while signed out).
  Future<void> _register() async {
    if (!_ready || session.isGuest) return;
    try {
      _token ??= await FirebaseMessaging.instance.getToken();
      final token = _token;
      if (token == null) return;
      await dioClient.post(
        ApiLinks.notificationsDevices,
        data: {'token': token, 'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android', 'language': language()},
      );
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Tells the backend to stop sending to this device; must run while the session token is still valid.
  Future<void> unregister() async {
    final token = _token;
    if (!_ready || token == null) return;
    try {
      await dioClient.request(ApiLinks.notificationsDevices, method: 'DELETE', data: {'token': token});
    } catch (_) {
      // Best effort: the backend also drops tokens FCM reports as dead.
    }
  }

  /// The string-only `data` of a push message.
  Map<String, String> _payload(RemoteMessage message) => message.data.map((k, v) => MapEntry(k, '$v'));
}
