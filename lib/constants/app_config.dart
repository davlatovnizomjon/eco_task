/// Build-time switches that decide which backend the app talks to.
///
/// Both values can be overridden per build:
/// `flutter run --dart-define=USE_MOCK_DATA=true --dart-define=API_HOST=http://10.0.2.2:8000`
class AppConfig {
  /// Private constructor — the class is a namespace of constants.
  const AppConfig._();

  /// While true every request is answered by `MockDioClient` from the
  /// in-memory store behind `mock_json_data/`, so every flow is demoable with
  /// no server. While false the app talks to the Django backend; the few
  /// features it does not have yet (expenses, requests, dashboard, reports)
  /// are still answered by the mock store. Nothing else changes when it
  /// flips: repositories, blocs and screens are identical either way.
  static const useMockData = bool.fromEnvironment('USE_MOCK_DATA');

  /// Telegram bot clients are sent to (the mobile app no longer serves the client role).
  static const telegramBot = String.fromEnvironment('TELEGRAM_BOT', defaultValue: '@eco_tasks_bot');

  /// Origin of the backend, without a path (`http://localhost:8000` for a local `runserver`).
  static const apiHost = String.fromEnvironment('API_HOST', defaultValue: 'http://localhost:8000');
}
