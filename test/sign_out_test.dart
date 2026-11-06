import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumora/features/caregiver_dashboard/parent_dashboard_screen.dart';
import 'package:lumora/features/child_home/child_home_screen.dart';
import 'package:lumora/models/user_role.dart';
import 'package:lumora/providers/communication_provider.dart';
import 'package:lumora/providers/learning_provider.dart';
import 'package:lumora/providers/routine_provider.dart';
import 'package:lumora/providers/safety_provider.dart';
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
      ChangeNotifierProvider<CommunicationProvider>(
          create: (_) => CommunicationProvider(settings)),
      ChangeNotifierProvider<RoutineProvider>(
          create: (_) => RoutineProvider(settings)),
      ChangeNotifierProvider<SafetyProvider>(
          create: (_) => SafetyProvider(settings)),
      ChangeNotifierProvider<LearningProvider>(
          create: (_) => LearningProvider(settings)),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The app loads intl's locale data in main(); tests that build screens
  // directly must do the same.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Role routing', () {
    test('only the child role opens the child home', () async {
      final SettingsProvider settings = await _newSettings();
      final SessionProvider session = SessionProvider(settings);

      await session.setRole(UserRole.child);
      expect(session.homeRoute, '/child-home');

      // Parent, teacher, therapist and caregiver all use the dashboard.
      for (final UserRole role in <UserRole>[
        UserRole.parent,
        UserRole.teacher,
        UserRole.therapist,
        UserRole.caregiver,
      ]) {
        await session.setRole(role);
        expect(session.homeRoute, '/parent-dashboard',
            reason: 'role ${role.nameId} should open the dashboard');
      }
    });
  });

  group('Saved session', () {
    testWidgets('a signed-in user is restored on the next start until sign out',
        (WidgetTester tester) async {
      final SettingsProvider settings = await _newSettings();

      // Storage work runs inside runAsync(): real file I/O only progresses
      // there while a widget test is running.
      await tester.runAsync(() async {
        setUpTempStorage();
        await LumoraRepository.instance.init();

        final SessionProvider first = SessionProvider(settings);
        await first.startDemo(role: UserRole.parent);
        expect(first.user, isNotNull);

        // Simulate opening the app again: a fresh provider reads the stored
        // session instead of asking the user to sign in.
        final SessionProvider reopened = SessionProvider(settings);
        expect(reopened.user, isNull);
        await reopened.restoreSession();
        expect(reopened.user, isNotNull);
        expect(reopened.role, UserRole.parent);

        // Signing out forgets it, so the next start shows Sign in again.
        await reopened.signOut();
        final SessionProvider afterSignOut = SessionProvider(settings);
        await afterSignOut.restoreSession();
        expect(afterSignOut.user, isNull);
        expect(afterSignOut.role, UserRole.child);
      });
    });
  });

  group('Sign out in every role', () {
    testWidgets('the dashboard (parent / teacher / therapist / caregiver) '
        'shows a sign-out action', (WidgetTester tester) async {
      for (final UserRole role in <UserRole>[
        UserRole.parent,
        UserRole.teacher,
        UserRole.therapist,
        UserRole.caregiver,
      ]) {
        final SettingsProvider settings = await _newSettings();
        final SessionProvider session = SessionProvider(settings);
        await tester.runAsync(() async {
          setUpTempStorage();
          await LumoraRepository.instance.init();
        });
        await session.startDemo(role: role);

        await tester.pumpWidget(MultiProvider(
          providers: _providers(settings, session),
          child: const MaterialApp(home: ParentDashboardScreen()),
        ));
        await tester.pump();

        expect(find.byIcon(Icons.logout), findsOneWidget,
            reason: 'role ${role.nameId} should offer sign out');
      }
    });

    testWidgets('the child home shows a sign-out action',
        (WidgetTester tester) async {
      final SettingsProvider settings = await _newSettings();
      final SessionProvider session = SessionProvider(settings);
      await tester.runAsync(() async {
        setUpTempStorage();
        await LumoraRepository.instance.init();
      });
      await session.startDemo(role: UserRole.child);

      await tester.pumpWidget(MultiProvider(
        providers: _providers(settings, session),
        child: const MaterialApp(home: ChildHomeScreen()),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
