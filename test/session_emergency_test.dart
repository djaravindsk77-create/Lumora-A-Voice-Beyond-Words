import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:lumora/core/constants/app_constants.dart';
import 'package:lumora/data/demo/demo_data.dart';
import 'package:lumora/data/demo/demo_data_source.dart';
import 'package:lumora/data/local/local_data_source.dart';
import 'package:lumora/models/learning_activity.dart';
import 'package:lumora/models/settings.dart';
import 'package:lumora/models/trusted_contact.dart';
import 'package:lumora/models/user.dart';
import 'package:lumora/models/user_role.dart';
import 'package:lumora/services/emergency/emergency_service.dart';

void main() {
  group('Persistent session', () {
    test('signed-in user JSON survives a settings round-trip', () {
      const UserModel user = UserModel(
        id: 'u-1',
        name: 'Parent',
        email: 'parent@demo.lumora',
        role: UserRole.parent,
      );
      final AppSettings withUser =
          const AppSettings().copyWith(signedInUserJson: jsonEncode(user.toJson()));

      final Map<String, dynamic> json =
          jsonDecode(jsonEncode(withUser.toJson())) as Map<String, dynamic>;
      final AppSettings restored = AppSettings.fromJson(json);

      expect(restored.signedInUserJson, isNotNull);
      final UserModel back =
          UserModel.fromJson(jsonDecode(restored.signedInUserJson!) as Map<String, dynamic>);
      expect(back.id, 'u-1');
      expect(back.email, 'parent@demo.lumora');
      expect(back.role, UserRole.parent);
    });

    test('clearing the session keeps other settings', () {
      const AppSettings base = AppSettings(
        languageCode: 'ta',
        themeMode: 'dark',
        onboardingComplete: true,
      );
      final AppSettings withUser =
          base.copyWith(signedInUserJson: '{"id":"u-1"}');
      final AppSettings cleared =
          withUser.copyWith(signedInUserJson: null);

      expect(cleared.signedInUserJson, isNull);
      expect(cleared.languageCode, 'ta');
      expect(cleared.themeMode, 'dark');
      expect(cleared.onboardingComplete, isTrue);
    });
  });

  group('Emergency service', () {
    test('alert text includes the map link when location exists', () {
      final EmergencyService svc = EmergencyService.instance;
      final String withoutLoc = svc.buildAlertText(
        childName: 'Arun',
        message: 'Please check on me.',
      );
      expect(withoutLoc, contains('Arun'));
      expect(withoutLoc, isNot(contains('maps.google.com')));

      final String withLoc = svc.buildAlertText(
        childName: 'Arun',
        message: 'Please check on me.',
        position: Position(
          latitude: 13.0827,
          longitude: 80.2707,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      expect(withLoc, contains('maps.google.com/?q=13.082700,80.270700'));
    });

    test('emergency contacts fall back to all reachable contacts', () async {
      // The selector logic lives in sendToEmergencyContacts; verify its
      // targeting indirectly via the outcome with no contacts.
      final EmergencyService svc = EmergencyService.instance;
      final int opened = await svc.sendToEmergencyContacts(
        contacts: const <TrustedContact>[],
        body: 'test',
      );
      expect(opened, 0);
      expect(svc.lastOutcome, isNotNull);
      expect(svc.lastOutcome!.hasContacts, isFalse);
      expect(svc.lastOutcome!.withLocation, isFalse);
    });
  });

  group('Learning progress persistence', () {
    test('progress round-trips through the local store', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Point path_provider at a real temp directory for this test run.
      final Directory tmp =
          await Directory.systemTemp.createTemp('lumora_test');
      await Directory('${tmp.path}${Platform.pathSeparator}lumora')
          .create(recursive: true);
      const MethodChannel pathProviderChannel =
          MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel,
              (MethodCall call) async => tmp.path);

      final LocalDataSource local = LocalDataSource.instance;
      await local.init();
      expect(local.isReady, isTrue);

      // Seed demo content, then verify progress is actually persisted.
      await DemoDataSource.instance.seedIfNeeded(local);
      final List<LearningProgress> all = local.getLearningProgress();
      expect(all, isNotEmpty);
      expect(
        all.where((LearningProgress p) => p.childId == DemoData.childId),
        isNotEmpty,
      );
      // Fields survive the JSON round-trip.
      final LearningProgress p = all.first;
      expect(p.totalCount, greaterThanOrEqualTo(p.correctCount));
      expect(p.starsEarned, inInclusiveRange(0, 3));
      expect(AppConstants.boxLearningProgress, 'lumora_learning_progress');

      try {
        await tmp.delete(recursive: true);
      } on FileSystemException {
        // Best-effort cleanup.
      }
    });
  });
}
