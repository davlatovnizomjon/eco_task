import 'package:flutter/material.dart';

import '../services/local_store.dart';

/// Immutable snapshot of every device setting the UI reads.
class AppSettings {
  /// Selected theme mode.
  final ThemeMode themeMode;

  /// True when notifications are allowed on this device.
  final bool permOn;

  /// True when text follows the phone's font scale.
  final bool bigText;

  /// True when quiet hours are on.
  final bool quiet;

  /// True when the morning digest is on.
  final bool morning;

  /// True when overdue tasks are reminded daily.
  final bool daily;

  /// Keys of notification switches turned off.
  final Set<String> off;

  /// Enabled reminder offsets (`m15`, `h1`, `d1`).
  final Set<String> remind;

  /// Builds a snapshot from its parts.
  const AppSettings({
    required this.themeMode,
    required this.permOn,
    required this.bigText,
    required this.quiet,
    required this.morning,
    required this.daily,
    required this.off,
    required this.remind,
  });

  /// Copy with the given fields replaced.
  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? permOn,
    bool? bigText,
    bool? quiet,
    bool? morning,
    bool? daily,
    Set<String>? off,
    Set<String>? remind,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    permOn: permOn ?? this.permOn,
    bigText: bigText ?? this.bigText,
    quiet: quiet ?? this.quiet,
    morning: morning ?? this.morning,
    daily: daily ?? this.daily,
    off: off ?? this.off,
    remind: remind ?? this.remind,
  );
}

/// Owns the device settings (theme, notification switches).
/// Screens listen to [settings] and call the setters; nothing is mirrored in
/// a bloc. Provided once at the root of the widget tree.
class SettingsRepository {
  /// Persistent backing store.
  final LocalStore _local;

  /// Current settings; every listener rebuilds when a setter publishes.
  final ValueNotifier<AppSettings> settings;

  /// Restores the persisted settings.
  SettingsRepository(LocalStore local)
    : _local = local,
      settings = ValueNotifier(
        AppSettings(
          themeMode: ThemeMode.values.firstWhere((m) => m.name == local.theme, orElse: () => ThemeMode.system),
          permOn: local.permOn,
          bigText: local.bigText,
          quiet: local.quiet,
          morning: local.morning,
          daily: local.daily,
          off: local.off.toSet(),
          remind: local.remind.toSet(),
        ),
      );

  /// Current snapshot.
  AppSettings get value => settings.value;

  /// Stores and publishes the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _local.setTheme(mode.name);
    settings.value = value.copyWith(themeMode: mode);
  }

  /// Stores whether notifications are allowed.
  Future<void> setNotificationsAllowed({required bool allowed}) async {
    await _local.setPermOn(allowed);
    settings.value = value.copyWith(permOn: allowed);
  }

  /// Flips one notification switch (`newTask`, `status`, `comment`, ...).
  Future<void> toggleNotification(String key) async {
    final next = {...value.off};
    if (!next.remove(key)) next.add(key);
    await _local.setOff(next.toList());
    settings.value = value.copyWith(off: next);
  }

  /// Flips one reminder offset (`m15`, `h1`, `d1`).
  Future<void> toggleReminder(String key) async {
    final next = {...value.remind};
    if (!next.remove(key)) next.add(key);
    await _local.setRemind(next.toList());
    settings.value = value.copyWith(remind: next);
  }

  /// Stores and publishes the "bigger text" switch.
  Future<void> setBigText(bool on) async {
    await _local.setBigText(on);
    settings.value = value.copyWith(bigText: on);
  }

  /// Stores and publishes the "quiet hours" switch.
  Future<void> setQuiet(bool on) async {
    await _local.setQuiet(on);
    settings.value = value.copyWith(quiet: on);
  }

  /// Stores and publishes the "morning digest" switch.
  Future<void> setMorning(bool on) async {
    await _local.setMorning(on);
    settings.value = value.copyWith(morning: on);
  }

  /// Stores and publishes the "daily overdue reminder" switch.
  Future<void> setDaily(bool on) async {
    await _local.setDaily(on);
    settings.value = value.copyWith(daily: on);
  }

  /// Releases the notifier when the app root is torn down.
  void dispose() => settings.dispose();
}
