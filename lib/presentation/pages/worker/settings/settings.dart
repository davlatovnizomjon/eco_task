/// Public surface of Settings: language, appearance, notifications and
/// deadline reminders. The screens are reactive — they listen to the app-wide
/// `SettingsRepository` and call its setters; the feature has no bloc.
library;

export 'presentation/appearance_screen.dart';
export 'presentation/language_settings_screen.dart';
export 'presentation/notification_settings_screen.dart';
export 'presentation/reminder_screen.dart';
