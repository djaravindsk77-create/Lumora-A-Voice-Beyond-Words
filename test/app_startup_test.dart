import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumora/app.dart';
import 'package:lumora/core/routing/app_router.dart';
import 'package:lumora/providers/settings_provider.dart';
import 'package:lumora/repositories/lumora_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App startup & routing', () {
    testWidgets('LumoraApp builds and shows the splash brand',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final SettingsProvider settings = SettingsProvider(prefs);
      await settings.load();

      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsProvider>.value(
          value: settings,
          child: const LumoraApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Lumora'), findsWidgets);
    });

    test('router exposes every required route name', () {
      final Set<String> names = appRouter.configuration.routes
          .expand((RouteBase r) => _routeNames(r))
          .toSet();
      const List<String> required = <String>[
        'splash', 'welcome', 'onboarding', 'roleSelect', 'language',
        'accessibilitySetup', 'login', 'register', 'forgotPassword',
        'childSetup', 'childHome', 'voice', 'aac', 'sentenceBuilder',
        'needs', 'emotions', 'tracker', 'contextModes', 'learn',
        'stories', 'creative', 'routines', 'timer', 'reminders', 'calm',
        'safety', 'trustedContacts', 'lostMode', 'profile',
        'notifications', 'parentDashboard', 'childManagement',
        'contentManagement', 'collaboration', 'reports', 'settings',
      ];
      for (final String name in required) {
        expect(names.contains(name), isTrue, reason: 'Missing route: $name');
      }
    });
  });

  group('Offline data access (local store)', () {
    test('repository initialises and seeds demo content', () async {
      final LumoraRepository repo = LumoraRepository.instance;
      await repo.init();

      expect(repo.getChildren(), isNotEmpty);
      expect(repo.getCategories().length, 16);
      expect(repo.getCardsForCategory('cat-food'), isNotEmpty);
      expect(repo.getPhrases(), isNotEmpty);
      expect(repo.getContacts(), isNotEmpty);
      expect(repo.getRoutines(), isNotEmpty);
      expect(repo.getCommActivities(), isNotEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

Set<String> _routeNames(RouteBase route) {
  final Set<String> out = <String>{};
  void walk(RouteBase r) {
    if (r is GoRoute) {
      if (r.name != null) out.add(r.name!);
      for (final RouteBase child in r.routes) {
        walk(child);
      }
    }
  }

  walk(route);
  return out;
}
