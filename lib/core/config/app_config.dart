/// Global runtime configuration for Lumora.
///
/// Lumora ships in two data modes:
///  * [DataMode.demo]     – everything runs locally with fictional sample data.
///  * [DataMode.firebase] – Firebase back end is used for auth/cloud data.
///
/// The mode can be forced from `--dart-define` (see `.env.example`) and
/// toggled at runtime from Settings (only when Firebase is available).
library;

enum DataMode { demo, firebase }

class AppConfig {
  AppConfig._();

  /// Application display name.
  static const String appName = 'Lumora';

  /// Application tagline.
  static const String tagline = 'Every voice matters.';

  /// Application version (kept in sync with pubspec.yaml manually).
  static const String appVersion = '1.0.0';

  /// Current data mode. Overridden at startup from the environment.
  static DataMode dataMode = DataMode.demo;

  /// Whether AI-backed features should be attempted. When false (or when no
  /// AI endpoint is configured) the rule-based fallback engine is used.
  static bool enableAi = false;

  /// Whether consent-based location features may be offered at all.
  static bool enableLocation = false;

  /// Whether cloud sync may be attempted when Firebase is configured.
  static bool enableCloudSync = false;

  /// Optional AI endpoint. Empty means AI features use the local fallback.
  static String aiEndpoint = '';

  /// True when the app has a usable remote back end.
  static bool get isFirebaseAvailable =>
      dataMode == DataMode.firebase && _firebaseInitialized;

  static bool _firebaseInitialized = false;

  /// Called by the bootstrap after a successful Firebase initialisation.
  static void markFirebaseInitialized() => _firebaseInitialized = true;

  /// Resets dynamic configuration (used by tests).
  static void reset() {
    dataMode = DataMode.demo;
    enableAi = false;
    enableLocation = false;
    enableCloudSync = false;
    aiEndpoint = '';
    _firebaseInitialized = false;
  }
}
