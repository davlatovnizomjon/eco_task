/// Public surface of the worker settings: the language and appearance sheets opened from the profile. The sheets are
/// reactive — they call the app-wide `SettingsRepository` and the localization context; the feature has no bloc.
library;

export 'presentation/theme_sheet.dart';
