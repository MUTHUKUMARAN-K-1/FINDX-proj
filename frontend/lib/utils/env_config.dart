/// Environment configuration for the FindX app
///
/// API keys are loaded from environment variables at compile time.
///
/// For development, create a .env file in the project root and run:
/// flutter run --dart-define-from-file=.env
///
/// For production builds:
/// flutter build apk --dart-define=GOOGLE_MAPS_API_KEY=your_key --dart-define=GEMINI_API_KEY=your_key
class EnvConfig {
  // Google Maps & Places API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // Must be set via dart-define
  );

  // Gemini API Key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Must be set via dart-define
  );

  // Backend API URL
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Check if Google Maps API key is configured
  static bool get hasGoogleMapsKey => googleMapsApiKey.isNotEmpty;

  /// Check if Gemini API key is configured
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Check if running in production mode
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  /// Check if debug mode
  static bool get isDebug => !isProduction;

  /// Validate that required keys are configured
  static void validateConfig() {
    final missing = <String>[];
    if (!hasGoogleMapsKey) missing.add('GOOGLE_MAPS_API_KEY');
    if (!hasGeminiKey) missing.add('GEMINI_API_KEY');

    if (missing.isNotEmpty && isProduction) {
      throw Exception(
        'Missing required environment variables: ${missing.join(', ')}',
      );
    }
  }
}
