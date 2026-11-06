import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumora/core/theme/app_colors.dart';
import 'package:lumora/providers/safety_provider.dart';
import 'package:lumora/providers/settings_provider.dart';
import 'package:lumora/widgets/siren_flash_overlay.dart';

Future<SettingsProvider> _newSettings() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final SettingsProvider settings = SettingsProvider(prefs);
  await settings.load();
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the siren screen flashes red and white',
      (WidgetTester tester) async {
    final SettingsProvider settings = await _newSettings();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: SirenFlashOverlay(
            onStopSiren: () {},
            onHideFlash: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder flash = find.byType(SirenFlashOverlay);
    final Finder background = find
        .descendant(of: flash, matching: find.byType(ColoredBox))
        .first;
    Color backgroundColour() => tester.widget<ColoredBox>(background).color;

    // Starts bright white, then travels towards emergency red.
    expect(backgroundColour(), Colors.white);
    await tester.pump(const Duration(milliseconds: 240));
    final Color midway = backgroundColour();
    expect(midway, isNot(Colors.white));
    expect(midway.g, lessThan(Colors.white.g));
    expect(midway.r, greaterThan(AppColors.error.r));

    // Emergency wording is visible.
    expect(find.text('EMERGENCY'), findsOneWidget);
    expect(
      find.text(
        'The siren is playing. Get help, stop the siren, or hide this flashing screen.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('both ways out of the siren screen work',
      (WidgetTester tester) async {
    final SettingsProvider settings = await _newSettings();
    bool stopped = false;
    bool hidden = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: SirenFlashOverlay(
            onStopSiren: () => stopped = true,
            onHideFlash: () => hidden = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Hide flashing screen'));
    expect(hidden, isTrue);
    expect(stopped, isFalse);

    await tester.tap(find.text('Stop siren'));
    expect(stopped, isTrue);
  });

  test('hiding the flash can be undone while the siren keeps playing', () async {
    final SettingsProvider settings = await _newSettings();
    final SafetyProvider safety = SafetyProvider(settings);

    expect(safety.sirenFlashHidden, isFalse);
    safety.hideSirenFlash();
    expect(safety.sirenFlashHidden, isTrue);
    safety.showSirenFlash();
    expect(safety.sirenFlashHidden, isFalse);
  });
}
