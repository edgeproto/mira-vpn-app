/// Compile-time configuration from `--dart-define`.
///
/// **Production API URL:** pass at build/run time, e.g.
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
///
/// **Tests with a custom base URL:** `flutter test --dart-define=API_BASE_URL=https://test.example`
class AppConfig {
  AppConfig._();

  /// Default when `API_BASE_URL` is not passed.
  static const String kDefaultApiBaseUrl = 'http://95.217.206.233:18080';

  /// Backend base URL (no trailing slash).
  static String get apiBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: kDefaultApiBaseUrl,
      );
}
