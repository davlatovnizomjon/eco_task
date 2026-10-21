import 'package:shared_preferences/shared_preferences.dart';

/// Typed wrapper over `shared_preferences` for the device settings (theme,
/// notification switches). Only repositories use it.
class LocalStore {
  /// The platform preferences backing every getter and setter.
  final SharedPreferences _prefs;

  /// Wraps an already-opened [SharedPreferences].
  LocalStore(this._prefs);

  /// Opens the preferences; awaited once in `main()`.
  static Future<LocalStore> create() async => LocalStore(await SharedPreferences.getInstance());

  /// Key of the stored theme mode name.
  static const _theme = 'theme';

  /// Key of the "notifications allowed" flag.
  static const _permOn = 'perm_on';

  /// Key of the list of disabled notification switches.
  static const _off = 'notif_off';

  /// Key of the list of enabled reminder offsets.
  static const _remind = 'remind';

  /// Key of the "bigger text" switch.
  static const _bigText = 'big_text';

  /// Key of the "quiet hours" switch.
  static const _quiet = 'quiet';

  /// Key of the "morning digest" switch.
  static const _morning = 'morning';

  /// Key of the "daily overdue reminder" switch.
  static const _daily = 'daily';

  /// Stored theme mode name (`system`, `light`, `dark`).
  String get theme => _prefs.getString(_theme) ?? 'system';

  /// Persists the theme mode name.
  Future<void> setTheme(String value) => _prefs.setString(_theme, value);

  /// True when the user allowed notifications.
  bool get permOn => _prefs.getBool(_permOn) ?? false;

  /// Persists the notifications-allowed flag.
  Future<void> setPermOn(bool value) => _prefs.setBool(_permOn, value);

  /// Keys of the notification switches the user turned off.
  List<String> get off => _prefs.getStringList(_off) ?? const ['comment'];

  /// Persists the disabled notification switches.
  Future<void> setOff(List<String> value) => _prefs.setStringList(_off, value);

  /// Enabled reminder offsets (`m15`, `h1`, `d1`).
  List<String> get remind => _prefs.getStringList(_remind) ?? const ['h1', 'd1'];

  /// Persists the enabled reminder offsets.
  Future<void> setRemind(List<String> value) => _prefs.setStringList(_remind, value);

  /// True when the text should follow the phone's font scale.
  bool get bigText => _prefs.getBool(_bigText) ?? true;

  /// Persists the bigger-text switch.
  Future<void> setBigText(bool value) => _prefs.setBool(_bigText, value);

  /// True when quiet hours are on.
  bool get quiet => _prefs.getBool(_quiet) ?? true;

  /// Persists the quiet-hours switch.
  Future<void> setQuiet(bool value) => _prefs.setBool(_quiet, value);

  /// True when the morning digest is on.
  bool get morning => _prefs.getBool(_morning) ?? true;

  /// Persists the morning-digest switch.
  Future<void> setMorning(bool value) => _prefs.setBool(_morning, value);

  /// True when overdue tasks are reminded daily.
  bool get daily => _prefs.getBool(_daily) ?? true;

  /// Persists the daily-reminder switch.
  Future<void> setDaily(bool value) => _prefs.setBool(_daily, value);
}
