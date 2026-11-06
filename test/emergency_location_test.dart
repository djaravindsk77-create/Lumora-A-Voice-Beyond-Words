import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumora/core/localization/app_localizations.dart';
import 'package:lumora/features/safety/safety_screen.dart';
import 'package:lumora/models/trusted_contact.dart';
import 'package:lumora/models/user_role.dart';
import 'package:lumora/providers/safety_provider.dart';
import 'package:lumora/services/emergency/emergency_service.dart';
import 'package:lumora/providers/session_provider.dart';
import 'package:lumora/providers/settings_provider.dart';
import 'package:lumora/repositories/lumora_repository.dart';

import 'test_support.dart';

Future<SettingsProvider> _newSettings() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final SettingsProvider settings = SettingsProvider(prefs);
  await settings.load();
  return settings;
}

List<SingleChildWidget> _providers(
  SettingsProvider settings,
  SessionProvider session,
) =>
    <SingleChildWidget>[
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<SessionProvider>.value(value: session),
      ChangeNotifierProvider<SafetyProvider>(
          create: (_) => SafetyProvider(settings)),
    ];

/// Pumps the Safety screen with a signed-in child, ready to press EMERGENCY.
Future<({SettingsProvider settings, SafetyProvider safety})> _pumpSafety(
  WidgetTester tester,
) async {
  final SettingsProvider settings = await _newSettings();
  final SessionProvider session = SessionProvider(settings);
  await tester.runAsync(() async {
    setUpTempStorage();
    await LumoraRepository.instance.init();
  });
  await session.startDemo(role: UserRole.child);

  late SafetyProvider safety;
  await tester.pumpWidget(MultiProvider(
    providers: _providers(settings, session),
    child: Builder(builder: (BuildContext context) {
      safety = context.read<SafetyProvider>();
      return const MaterialApp(home: SafetyScreen());
    }),
  ));
  await tester.pump();
  return (settings: settings, safety: safety);
}

/// Presses the big EMERGENCY button and confirms the dialog.
Future<void> _pressEmergency(WidgetTester tester, {required bool share}) async {
  await tester.tap(find.text(
    AppLocalizations.tr('en', 'safety.emergencyButton'),
  ).first);
  await tester.pumpAndSettle();

  // The dialog asks explicitly whether to include the location.
  expect(
    find.text(AppLocalizations.tr('en', 'safety.shareLocationAlert')),
    findsOneWidget,
  );

  final bool currentlyOn = tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile))
          .value ??
      false;
  if (currentlyOn != share) {
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
  }

  await tester.tap(find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(FilledButton),
  ).first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Emergency alert location', () {
    testWidgets('pressing EMERGENCY asks for the location and records consent',
        (WidgetTester tester) async {
      final ({SettingsProvider settings, SafetyProvider safety}) ctx =
          await _pumpSafety(tester);

      // Before the first emergency no location consent is recorded: that was
      // exactly why alerts used to go out without the coordinates.
      expect(ctx.settings.settings.locationConsent, isFalse);

      await _pressEmergency(tester, share: true);

      // The consent given in the emergency dialog is stored, so this alert -
      // and every later one - carries the location.
      expect(ctx.settings.settings.locationConsent, isTrue);

      // The screen always says what happened with the location, so a missing
      // fix is never silent (a test host has no GPS).
      expect(ctx.safety.locationNote, isNotNull);
      expect(
        ctx.settings.settings.locationConsent,
        isTrue,
        reason: 'the in-flow consent must persist for later alerts',
      );
    });

    testWidgets('opting out keeps the alert but records no location consent',
        (WidgetTester tester) async {
      final ({SettingsProvider settings, SafetyProvider safety}) ctx =
          await _pumpSafety(tester);

      await _pressEmergency(tester, share: false);

      expect(ctx.settings.settings.locationConsent, isFalse);
      expect(ctx.safety.emergencyPosition, isNull);
      expect(
        ctx.safety.locationNote,
        AppLocalizations.tr('en', 'emergency.locNotShared'),
      );
      // The alert itself still went out and is logged.
      expect(ctx.safety.alerts, isNotEmpty);
    });

    test('the alert reaches every reachable contact, most important first',
        () {
      final EmergencyService svc = EmergencyService.instance;
      final List<TrustedContact> targets = svc.emergencyTargets(
        const <TrustedContact>[
          TrustedContact(
            id: 'c-teacher',
            childId: 'child-1',
            name: 'Teacher',
            relationship: 'teacher',
            phone: '+919000000003',
          ),
          TrustedContact(
            id: 'c-mum',
            childId: 'child-1',
            name: 'Mum',
            relationship: 'parent',
            phone: '+919000000001',
            isPrimary: true,
          ),
          TrustedContact(
            id: 'c-revoked',
            childId: 'child-1',
            name: 'Revoked',
            relationship: 'emergency',
            phone: '+919000000004',
            hasAccess: false,
          ),
          TrustedContact(
            id: 'c-grandma',
            childId: 'child-1',
            name: 'Grandma',
            relationship: 'emergency',
            phone: '+919000000002',
          ),
        ],
      );

      // The revoked contact is never messaged, and everyone else is.
      expect(targets.map((TrustedContact c) => c.id),
          <String>['c-mum', 'c-grandma', 'c-teacher']);
      expect(targets.first.isPrimary, isTrue);
    });

    test('the alert body carries the coordinates as a map link', () {
      final EmergencyService svc = EmergencyService.instance;
      final String body = svc.buildAlertText(
        childName: 'Arun',
        message: 'Please check on me.',
        position: Position(
          latitude: 13.0827,
          longitude: 80.2707,
          timestamp: DateTime.now(),
          accuracy: 8,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      expect(body, contains('maps.google.com/?q=13.082700,80.270700'));
      expect(body, contains('Arun'));
    });
  });
}
