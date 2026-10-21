import 'dart:ui';

/// No-op Telegram bridge used outside the web build and outside Telegram.
abstract final class TelegramApp {
  /// True only inside a Telegram Mini App; always false here.
  static bool get isAvailable => false;

  /// Telegram's active color scheme; always false (light) here.
  static bool get isDark => false;

  /// Tells Telegram the app is ready and expands it; nothing to do here.
  static void init() {}

  /// Shows or hides Telegram's native back button; nothing to do here.
  static void setBackButton({required bool visible, required VoidCallback onBack}) {}

  /// Paints Telegram's header and background with [hex]; nothing to do here.
  static void setColors(String hex) {}
}
