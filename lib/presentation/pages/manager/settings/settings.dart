/// Public surface of the manager settings: the language and appearance sheets opened from the profile. The sheets are
/// reactive — they call the app-wide `SettingsRepository` and the localization context; the feature has no bloc.
library;

export 'presentation/language_sheet.dart';
export 'presentation/theme_sheet.dart';
