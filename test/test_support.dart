import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Directory? _tempDir;

/// Points `path_provider` (which Hive uses to find its directory) at a
/// throwaway temp folder so the offline store can initialise on a headless
/// test host.
///
/// Mobile/desktop builds have a real documents directory and web builds use
/// IndexedDB, so this only affects tests. The folder is created once per test
/// isolate and intentionally left in place: Hive keeps the path open for the
/// whole run, and removing it would break the singleton store.
Directory setUpTempStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Directory? existing = _tempDir;
  if (existing != null) return existing;

  final Directory tmp =
      Directory.systemTemp.createTempSync('lumora_test');
  Directory('${tmp.path}${Platform.pathSeparator}lumora')
      .createSync(recursive: true);

  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel,
          (MethodCall call) async => tmp.path);

  _tempDir = tmp;
  return tmp;
}
