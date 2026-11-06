import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lumora/core/localization/app_localizations.dart';
import 'package:lumora/features/onboarding/role_selection_screen.dart';
import 'package:lumora/features/onboarding/welcome_screen.dart';

/// Regression test for the navigation fix: in-app navigation uses push()
/// (grows the stack) instead of go() (replaces it), so screens get a working
/// back button and users no longer have to restart the app to leave a page.
void main() {
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    // Build the router inside the test so the test binding is installed first
    // (a GoRouter constructed at main() top level would initialize the
    // production WidgetsFlutterBinding and break the test binding).
    final GoRouter router = GoRouter(
      initialLocation: '/welcome',
      routes: <RouteBase>[
        GoRoute(
          path: '/welcome',
          builder: (_, __) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/role-select',
          builder: (_, __) => const RoleSelectionScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocales.supported,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('pushing a screen shows a back button and Back returns',
      (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Welcome -> Role Selection (now a stack push).
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);

    // The pushed route must expose an automatic back button.
    expect(find.byType(BackButton), findsOneWidget);
    expect(router.routerDelegate.canPop(), isTrue);

    // Tapping Back must return to Welcome.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(router.routerDelegate.canPop(), isFalse);
  });
}
