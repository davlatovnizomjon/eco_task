import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

/// Telegram Mini App bridge for the web build: reads the theme, expands the
/// window, blocks the swipe-to-close gesture and drives the native back button.
abstract final class TelegramApp {
  /// The page-level `Telegram.WebApp` object, or null outside Telegram.
  static JSObject? get _app {
    if (!globalContext.has('Telegram')) return null;
    final telegram = globalContext['Telegram'];
    if (telegram == null || !telegram.isA<JSObject>()) return null;
    final app = (telegram as JSObject)['WebApp'];
    return app != null && app.isA<JSObject>() ? app as JSObject : null;
  }

  /// Handler of the native back button; replaced on every [setBackButton] call.
  static VoidCallback? _onBack;

  /// True once the single JS click listener was registered.
  static bool _backWired = false;

  /// True only inside a Telegram Mini App.
  static bool get isAvailable => _app != null;

  /// True when Telegram currently uses its dark color scheme.
  static bool get isDark => (_app?['colorScheme'] as JSString?)?.toDart == 'dark';

  /// Tells Telegram the app is ready, expands it to full height and disables
  /// the vertical swipe that would close the app while pull-to-refresh is used.
  static void init() {
    final app = _app;
    if (app == null) return;
    app.callMethod('ready'.toJS);
    app.callMethod('expand'.toJS);
    // Available from Bot API 7.7; older clients simply lack the method.
    if (app.has('disableVerticalSwipes')) app.callMethod('disableVerticalSwipes'.toJS);
  }

  /// Shows or hides Telegram's native back button and routes its tap to [onBack].
  static void setBackButton({required bool visible, required VoidCallback onBack}) {
    final button = _app?['BackButton'];
    if (button == null || !button.isA<JSObject>()) return;
    final back = button as JSObject;
    _onBack = onBack;
    if (!_backWired) {
      _backWired = true;
      back.callMethod('onClick'.toJS, (() => _onBack?.call()).toJS);
    }
    back.callMethod((visible ? 'show' : 'hide').toJS);
  }

  /// Paints Telegram's header and background with the hex color [hex]
  /// (`#RRGGBB`); ignored by clients older than Bot API 6.1.
  static void setColors(String hex) {
    final app = _app;
    if (app == null) return;
    for (final method in const ['setHeaderColor', 'setBackgroundColor']) {
      if (app.has(method)) app.callMethod(method.toJS, hex.toJS);
    }
  }
}
