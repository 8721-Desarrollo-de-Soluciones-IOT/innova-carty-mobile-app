/// Where the app finds the Innova Carty Platform API (Spring Boot on Render).
///
/// To use another URL without editing code:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.35:8080/api/v1`
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://innova-carty-backend.onrender.com/api/v1',
  );

  /// Render free plan sleeps after 15 min; the first request can take about a minute.
  static const Duration requestTimeout = Duration(seconds: 75);

  /// Live refresh of the cart and the admin lists.
  static const Duration shopperRefresh = Duration(seconds: 3);
  static const Duration adminRefresh = Duration(seconds: 5);
}
