/// Placeholder for the Firebase-generated options file.
///
/// When you configure Firebase (see README → "Firebase setup"), run:
///
/// ```bash
/// dart pub global activate flutterfire_cli
/// flutterfire configure
/// ```
///
/// This generates `lib/core/config/firebase_options.g.dart` with your
/// project's `FirebaseOptions`. Then replace the body of
/// [getFirebaseOptions] to return it, e.g.:
///
/// ```dart
/// import '../../core/config/firebase_options.g.dart';
/// FirebaseOptions get getFirebaseOptions => DefaultFirebaseOptions.currentPlatform;
/// ```
///
/// Keeping this behind a stub means the project compiles and runs perfectly
/// (in Demo Mode) BEFORE Firebase is configured, without hardcoding keys.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

FirebaseOptions? get getFirebaseOptions => null;
