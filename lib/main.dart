import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/env_config.dart';
import 'core/utilities/feedback_service.dart';
import 'data/firebase/firebase_data_source.dart';
import 'providers/settings_provider.dart';
import 'repositories/lumora_repository.dart';
import 'services/notifications/notification_service.dart';
import 'services/speech/tts_service.dart';
import 'services/sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-first orientation suits the AAC board layout.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Apply dart-define environment flags (see .env.example).
  AppConfig.dataMode =
      EnvConfig.wantsFirebase ? DataMode.firebase : DataMode.demo;
  AppConfig.enableAi = EnvConfig.enableAi;
  AppConfig.enableLocation = EnvConfig.enableLocation;
  AppConfig.enableCloudSync = EnvConfig.enableCloudSync;
  AppConfig.aiEndpoint = EnvConfig.aiEndpoint;

  // Try Firebase first; on any failure the app stays in Demo Mode.
  if (AppConfig.dataMode == DataMode.firebase) {
    await FirebaseDataSource.instance.tryInitialize();
    if (!FirebaseDataSource.instance.isAvailable) {
      AppConfig.dataMode = DataMode.demo;
    }
  }

  // Offline-first storage + demo seeding.
  await LumoraRepository.instance.init();

  // Optional platform services - failures never block startup.
  await TtsService.instance.init();
  await NotificationService.instance.init();
  SyncService.instance.start();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final SettingsProvider settings = SettingsProvider(prefs);
  await settings.load();

  FeedbackService.soundEnabled = settings.accessibility.soundEnabled;
  FeedbackService.hapticsEnabled = settings.accessibility.hapticsEnabled;

  runApp(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const LumoraApp(),
    ),
  );
}
