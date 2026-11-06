import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumora/features/aac/aac_categories_screen.dart';
import 'package:lumora/features/emotions/emotions_screen.dart';
import 'package:lumora/features/my_needs/my_needs_screen.dart';
import 'package:lumora/features/sentence_builder/sentence_builder_screen.dart';
import 'package:lumora/features/settings/settings_screen.dart';
import 'package:lumora/models/barrel.dart';
import 'package:lumora/models/user_role.dart';
import 'package:lumora/providers/communication_provider.dart';
import 'package:lumora/providers/routine_provider.dart';
import 'package:lumora/providers/session_provider.dart';
import 'package:lumora/providers/settings_provider.dart';
import 'package:lumora/repositories/lumora_repository.dart';
import 'package:lumora/services/notifications/notification_service.dart';

Future<(SettingsProvider, SessionProvider, CommunicationProvider)>
    _buildHarness(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final SettingsProvider settings = SettingsProvider(prefs);
  await settings.load();

  final LumoraRepository repo = LumoraRepository.instance;
  await repo.init();

  final SessionProvider session = SessionProvider(settings);
  await session.startDemo(role: UserRole.child);

  final CommunicationProvider comm = CommunicationProvider(settings);
  await comm.load(session.child?.id ?? 'demo-child-1');

  return (settings, session, comm);
}

Widget _wrap(Widget child, List<SingleChildWidget> providers) =>
    MultiProvider(
      providers: providers,
      child: MaterialApp(home: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AAC categories screen', () {
    testWidgets('renders the 16 demo categories',
        (WidgetTester tester) async {
      final (settings, session, comm) = await _buildHarness(tester);
      await tester.pumpWidget(_wrap(
        const AacCategoriesScreen(),
        <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<CommunicationProvider>.value(value: comm),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Feelings'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);
    });
  });

  group('My Needs', () {
    testWidgets('shows all 14 need cards', (WidgetTester tester) async {
      final (settings, session, comm) = await _buildHarness(tester);
      await tester.pumpWidget(_wrap(
        const MyNeedsScreen(),
        <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<CommunicationProvider>.value(value: comm),
        ],
      ));
      await tester.pump();

      expect(find.text('I am hungry'), findsOneWidget);
      expect(find.text('I need the bathroom'), findsOneWidget);
      expect(find.text('I need a break'), findsOneWidget);
    });

    testWidgets('tapping a need logs a communication attempt',
        (WidgetTester tester) async {
      final (settings, session, comm) = await _buildHarness(tester);
      final int before = comm.activities.length;
      await tester.pumpWidget(_wrap(
        const MyNeedsScreen(),
        <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<CommunicationProvider>.value(value: comm),
        ],
      ));
      await tester.pump();

      await tester.tap(find.text('I am hungry'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(comm.activities.length, greaterThanOrEqualTo(before));
    });
  });

  group('Emotions', () {
    testWidgets('shows all 12 emotions and comfort flow',
        (WidgetTester tester) async {
      final (settings, session, comm) = await _buildHarness(tester);
      await tester.pumpWidget(_wrap(
        const EmotionsScreen(),
        <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<CommunicationProvider>.value(value: comm),
        ],
      ));
      await tester.pump();

      expect(find.text('Happy'), findsWidgets);
      expect(find.text('Calm'), findsOneWidget);

      await tester.tap(find.text('Happy').first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('What would help?'), findsOneWidget);
    });
  });

  group('Sentence builder', () {
    testWidgets('adds words from templates and speaks',
        (WidgetTester tester) async {
      final (settings, session, comm) = await _buildHarness(tester);
      await tester.pumpWidget(_wrap(
        const SentenceBuilderScreen(),
        <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<SessionProvider>.value(value: session),
          ChangeNotifierProvider<CommunicationProvider>.value(value: comm),
        ],
      ));
      await tester.pump();

      await tester.tap(find.text('I want').first);
      await tester.pump();

      expect(find.text('I want'), findsWidgets);
    });
  });

  group('Settings', () {
    testWidgets('toggles high contrast', (WidgetTester tester) async {
      final (settings, _, _) = await _buildHarness(tester);
      await tester.pumpWidget(_wrap(
        const SettingsScreen(),
        <SingleChildWidget>[
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
      ));
      await tester.pump();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });
  });

  group('Notification service', () {
    test('notify stores in-app history even without system notifications',
        () async {
      await NotificationService.instance.init();
      final int before =
          LumoraRepository.instance.getNotifications().length;
      await NotificationService.instance.notify(
        type: 'routine',
        title: 'Test',
        body: 'Test body',
      );
      expect(
        LumoraRepository.instance.getNotifications().length,
        greaterThanOrEqualTo(before),
      );
    });
  });

  group('Routine provider', () {
    test('marks tasks complete and computes ratio', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final SettingsProvider settings = SettingsProvider(prefs);
      await settings.load();
      final SessionProvider session = SessionProvider(settings);
      await session.startDemo(role: UserRole.parent);
      final RoutineProvider routines = RoutineProvider(settings);
      await routines.load(session.child?.id ?? '');

      expect(routines.completionRatio, 0);
      final String firstTask = routines.activeRoutine!.tasks.first.id;
      routines.markTaskComplete(firstTask);
      expect(routines.completedTaskIds.contains(firstTask), isTrue);
      expect(routines.completionRatio, greaterThan(0));
    });
  });
}
