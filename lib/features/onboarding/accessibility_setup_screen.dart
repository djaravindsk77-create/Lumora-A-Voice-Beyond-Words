import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/settings.dart';
import '../../providers/settings_provider.dart';

/// Accessibility setup during onboarding: text size, contrast, motion,
/// sound, haptics and large buttons - all editable later in Settings.
class AccessibilitySetupScreen extends StatelessWidget {
  const AccessibilitySetupScreen({super.key, this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final AccessibilitySettings a = settings.accessibility;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('onboarding.a11yTitle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              l.t('onboarding.a11ySubtitle'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _preset(
                  context,
                  label: l.t('a11y.presetDefault'),
                  preset: AccessibilitySettings.presetDefault,
                ),
                _preset(
                  context,
                  label: l.t('a11y.presetLarge'),
                  preset: AccessibilitySettings.presetLarge,
                ),
                _preset(
                  context,
                  label: l.t('a11y.presetCalm'),
                  preset: AccessibilitySettings.presetCalm,
                ),
                _preset(
                  context,
                  label: l.t('a11y.presetHighContrast'),
                  preset: AccessibilitySettings.presetHighContrast,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: <Widget>[
                  // Deliberately NOT a ListTile with a Slider subtitle: a
                  // ListTile keeps a fixed content height, so growing the text
                  // theme while dragging used to overflow and paint the
                  // yellow/black stripes. A Column grows with the text instead.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l.t('a11y.textSize'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(a.textScale * 100).round()}%',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      value: a.textScale,
                      min: AccessibilitySettings.minScale,
                      max: AccessibilitySettings.maxScale,
                      divisions: 8,
                      label: a.textScale.toStringAsFixed(1),
                      onChanged: (double v) => settings.setTextScale(v),
                    ),
                  ),
                  // Live preview of the chosen size.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.t('a11y.textPreview'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(l.t('a11y.highContrast')),
                    value: a.highContrast,
                    onChanged: (_) => settings.toggleHighContrast(),
                  ),
                  SwitchListTile(
                    title: Text(l.t('a11y.reducedMotion')),
                    value: a.reducedMotion,
                    onChanged: (_) => settings.toggleReducedMotion(),
                  ),
                  SwitchListTile(
                    title: Text(l.t('a11y.sound')),
                    value: a.soundEnabled,
                    onChanged: (_) => settings.toggleSound(),
                  ),
                  SwitchListTile(
                    title: Text(l.t('a11y.haptics')),
                    value: a.hapticsEnabled,
                    onChanged: (_) => settings.toggleHaptics(),
                  ),
                  SwitchListTile(
                    title: Text(l.t('a11y.largeButtons')),
                    value: a.largeButtons,
                    onChanged: (_) => settings.toggleLargeButtons(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final String r = role ?? 'child';
                  if (r == 'child') {
                    context.push('/login?demo=1&role=child');
                  } else {
                    context.push('/login');
                  }
                },
                child: Text(l.t('common.continue')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preset(BuildContext context,
      {required String label, required AccessibilitySettings preset}) {
    return OutlinedButton(
      onPressed: () =>
          context.read<SettingsProvider>().updateAccessibility(preset),
      child: Text(label),
    );
  }
}
