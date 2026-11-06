/// Reads optional environment values from `--dart-define` compile flags.
///
/// Real secrets are NEVER stored in source code. Provide values at build or
/// run time, for example:
///
/// ```bash
/// flutter run --dart-define=LUMORA_AI_ENDPOINT=https://api.example.com/v1
/// flutter build apk --release --dart-define=LUMORA_FIREBASE_API_KEY=xxxx
/// ```
///
/// See `.env.example` for the full list of supported keys. Every value is
/// optional: the app runs in Demo Mode when nothing is provided.
library;

class EnvConfig {
  EnvConfig._();

  static const String _dataMode = String.fromEnvironment(
    'LUMORA_DATA_MODE',
    defaultValue: 'demo',
  );
  static const bool _enableAi = bool.fromEnvironment(
    'LUMORA_ENABLE_AI',
    defaultValue: false,
  );
  static const bool _enableLocation = bool.fromEnvironment(
    'LUMORA_ENABLE_LOCATION',
    defaultValue: false,
  );
  static const bool _enableCloudSync = bool.fromEnvironment(
    'LUMORA_ENABLE_CLOUD_SYNC',
    defaultValue: false,
  );
  static const String aiEndpoint = String.fromEnvironment(
    'LUMORA_AI_ENDPOINT',
  );
  static const String aiApiKey = String.fromEnvironment('LUMORA_AI_API_KEY');
  static const String firebaseApiKey = String.fromEnvironment(
    'LUMORA_FIREBASE_API_KEY',
  );

  static bool get wantsFirebase => _dataMode == 'firebase';

  static bool get enableAi => _enableAi;
  static bool get enableLocation => _enableLocation;
  static bool get enableCloudSync => _enableCloudSync;
}
