/// Bridge to the Telegram Mini App runtime (`window.Telegram.WebApp`).
///
/// On the web build it talks to Telegram through JS interop; on every other
/// platform (and in a plain browser tab) the stub is used and every call is a
/// no-op, so the rest of the app never checks the platform.
library;

export 'telegram_stub.dart' if (dart.library.js_interop) 'telegram_web.dart';
