import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumora/core/localization/app_localizations.dart';
import 'package:lumora/core/theme/app_theme.dart';
import 'package:lumora/features/onboarding/accessibility_setup_screen.dart';
import 'package:lumora/features/settings/settings_screen.dart';
import 'package:lumora/models/settings.dart';
import 'package:lumora/providers/settings_provider.dart';

/// Regression guard for the yellow/black overflow stripes that appeared while
/// changing the text size on the accessibility screens.
///
/// The whole app rebuilds with a bigger text theme on every slider move, so any
/// fixed-height or non-wrapping row can overflow. These tests drive the real
/// scale changes at the maximum size and fail if a layout overflows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsProvider> buildSettings() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsProvider settings = SettingsProvider(prefs);
    await settings.load();
    return settings;
  }

  /// Mirrors `LumoraApp`: the theme is rebuilt from the live accessibility
  /// settings, exactly like the running app.
  Widget harness(SettingsProvider settings, Widget home) {
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: Consumer<SettingsProvider>(
        builder: (BuildContext context, SettingsProvider sp, _) {
          return MaterialApp(
            theme: AppTheme.light(
              textScale: sp.accessibility.textScale,
              highContrast: sp.accessibility.highContrast,
            ),
            home: home,
          );
        },
      ),
    );
  }

  testWidgets('accessibility setup screen never overflows across text sizes',
      (WidgetTester tester) async {
    final SettingsProvider settings = await buildSettings();
    await tester.pumpWidget(
      harness(settings, const AccessibilitySetupScreen(role: 'child')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Step through every text size the slider can produce.
    for (final double scale in <double>[1.0, 1.2, 1.4, 1.6, 1.8]) {
      await settings.setTextScale(scale);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflowed at text scale $scale',
      );
    }

    // And once more with a narrow (small phone) viewport at max text size.
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await settings.setTextScale(AccessibilitySettings.maxScale);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('accessibility screen survives a preset with large text',
      (WidgetTester tester) async {
    final SettingsProvider settings = await buildSettings();
    await tester.pumpWidget(
      harness(settings, const AccessibilitySetupScreen(role: 'parent')),
    );
    await tester.pumpAndSettle();

    // High-contrast preset both ups the text scale and thickens borders.
    await settings.updateAccessibility(
      AccessibilitySettings.presetHighContrast,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging the text size in Settings never overflows',
      (WidgetTester tester) async {
    final SettingsProvider settings = await buildSettings();
    await tester.pumpWidget(harness(settings, const SettingsScreen()));
    await tester.pumpAndSettle();

    // Open the accessibility page from Settings - the screen the user was on
    // when the yellow/black stripes appeared.
    await tester.tap(find.text(AppLocalizations.tr('en', 'settings.a11y')));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);

    // Drag the slider the way a finger would, several times, and check that
    // no layout overflows while the whole app rebuilds at the new size.
    for (int i = 0; i < 4; i++) {
      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflowed after drag ${i + 1} at scale '
            '${settings.accessibility.textScale}',
      );
    }

    // Narrow phone, maximum text size: the worst case for this screen.
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await settings.setTextScale(AccessibilitySettings.maxScale);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });
}
