import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/firebase/firebase_data_source.dart';
import '../../models/settings.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';
import '../onboarding/language_selection_screen.dart';


/// Settings hub: theme, language, accessibility, notifications (with quiet
/// hours), privacy/consent, data mode and about. Every switch persists.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SettingsProvider sp = context.watch<SettingsProvider>();
    final AppSettings s = sp.settings;
    final FirebaseDataSource fb = FirebaseDataSource.instance;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SizedBox(height: 8),
          // Appearance
          Text(l.t('settings.theme'),
              style: Theme.of(context).textTheme.titleSmall),
          // Choice chips in a Wrap rather than a SegmentedButton: at a large
          // text size a segmented button cannot wrap and overflows.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(l.t('settings.themeLight')),
                selected: sp.themeChoice == ThemeChoice.light,
                onSelected: (_) => sp.setThemeChoice(ThemeChoice.light),
              ),
              ChoiceChip(
                label: Text(l.t('settings.themeDark')),
                selected: sp.themeChoice == ThemeChoice.dark,
                onSelected: (_) => sp.setThemeChoice(ThemeChoice.dark),
              ),
              ChoiceChip(
                label: Text(l.t('settings.themeSystem')),
                selected: sp.themeChoice == ThemeChoice.system,
                onSelected: (_) => sp.setThemeChoice(ThemeChoice.system),
              ),
            ],
          ),
          const Divider(height: 28),
          // Language
          Text(l.t('settings.language'),
              style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: LanguageSelectionScreen.all
                .map((loc) => ChoiceChip(
                      label: Text(AppLocales.displayName(loc)),
                      selected:
                          s.languageCode == AppLocales.code(loc),
                      onSelected: (_) =>
                          sp.setLanguage(AppLocales.code(loc)),
                    ))
                .toList(),
          ),
          const Divider(height: 28),
          // Accessibility
          ListTile(
            leading: const Icon(Icons.accessibility),
            title: Text(l.t('settings.a11y')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  const _AccessibilitySettingsPage(),
            )),
          ),
          // Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l.t('settings.notifications')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  const _NotificationSettingsPage(),
            )),
          ),
          // Privacy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l.t('settings.privacy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  const _PrivacySettingsPage(),
            )),
          ),
          const Divider(height: 28),
          // Data mode (honest state).
          Text(l.t('settings.dataMode'),
              style: Theme.of(context).textTheme.titleSmall),
          RadioGroup<bool>(
            groupValue: AppConfig.isFirebaseAvailable,
            onChanged: (bool? v) {},
            child: Column(
              children: <Widget>[
                RadioListTile<bool>(
                  title: Text(l.t('settings.modeDemo')),
                  value: false,
                ),
                RadioListTile<bool>(
                  title: Text(l.t('settings.modeFirebase')),
                  value: true,
                  secondary: Icon(fb.isAvailable
                      ? Icons.cloud_done
                      : Icons.cloud_off),
                ),
              ],
            ),
          ),
          if (!fb.isAvailable)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Text(l.t('settings.fbNotConfigured'),
                  style: Theme.of(context).textTheme.labelSmall),
            ),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(l.t('settings.about')),
            subtitle: Text(
                '${l.t('settings.version')} ${AppConfig.appVersion}'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (BuildContext context) => const _AboutPage(),
            )),
          ),
          ListTile(
            leading: const Icon(Icons.help_center),
            title: Text(l.t('settings.help')),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(
              builder: (BuildContext context) => const _HelpPage(),
            )),
          ),
          const Divider(height: 28),
          // Sign out is reachable from Settings for every role.
          const SignOutTile(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Accessibility settings page
// ---------------------------------------------------------------------

class _AccessibilitySettingsPage extends StatelessWidget {
  const _AccessibilitySettingsPage();

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SettingsProvider sp = context.watch<SettingsProvider>();
    final AccessibilitySettings a = sp.accessibility;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.a11y'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // A ListTile with a Slider subtitle has a fixed content height and
          // overflowed (yellow/black stripes) as soon as the text theme grew.
          // Plain rows wrap and grow instead.
          Card(
            child: Column(
              children: <Widget>[
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
                    onChanged: sp.setTextScale,
                  ),
                ),
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
              ],
            ),
          ),
          SwitchListTile(
            title: Text(l.t('a11y.highContrast')),
            value: a.highContrast,
            onChanged: (_) => sp.toggleHighContrast(),
          ),
          SwitchListTile(
            title: Text(l.t('a11y.reducedMotion')),
            value: a.reducedMotion,
            onChanged: (_) => sp.toggleReducedMotion(),
          ),
          SwitchListTile(
            title: Text(l.t('a11y.sound')),
            value: a.soundEnabled,
            onChanged: (_) => sp.toggleSound(),
          ),
          SwitchListTile(
            title: Text(l.t('a11y.haptics')),
            value: a.hapticsEnabled,
            onChanged: (_) => sp.toggleHaptics(),
          ),
          SwitchListTile(
            title: Text(l.t('a11y.largeButtons')),
            value: a.largeButtons,
            onChanged: (_) => sp.toggleLargeButtons(),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: sp.resetAccessibility,
            child: Text(l.t('settings.resetA11y')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Notification settings page
// ---------------------------------------------------------------------

class _NotificationSettingsPage extends StatelessWidget {
  const _NotificationSettingsPage();

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SettingsProvider sp = context.watch<SettingsProvider>();
    final AppSettings s = sp.settings;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.notifications'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SwitchListTile(
            title: Text(l.t('settings.notifRoutine')),
            value: s.notifRoutine,
            onChanged: (bool v) => sp.updateNotifPref('routine', v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.notifActivity')),
            value: s.notifActivity,
            onChanged: (bool v) => sp.updateNotifPref('activity', v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.notifAlerts')),
            value: s.notifAlerts,
            onChanged: (bool v) => sp.updateNotifPref('alert', v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.notifAssigned')),
            value: s.notifAssigned,
            onChanged: (bool v) => sp.updateNotifPref('assigned', v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.notifNotes')),
            value: s.notifNotes,
            onChanged: (bool v) => sp.updateNotifPref('notes', v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.notifEvents')),
            value: s.notifEvents,
            onChanged: (bool v) => sp.updateNotifPref('events', v),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l.t('settings.quietHours')),
            value: s.quietHoursEnabled,
            onChanged: (bool v) => sp.setQuietHours(
              enabled: v,
              startMinutes: s.quietStartMinutes,
              endMinutes: s.quietEndMinutes,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${l.t('settings.quietStart')} '
              '${(s.quietStartMinutes ~/ 60).toString().padLeft(2, '0')}:'
              '${(s.quietStartMinutes % 60).toString().padLeft(2, '0')}  '
              '${l.t('settings.quietEnd')} '
              '${(s.quietEndMinutes ~/ 60).toString().padLeft(2, '0')}:'
              '${(s.quietEndMinutes % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Privacy settings page
// ---------------------------------------------------------------------

class _PrivacySettingsPage extends StatelessWidget {
  const _PrivacySettingsPage();

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SettingsProvider sp = context.watch<SettingsProvider>();
    final AppSettings s = sp.settings;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.privacy'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l.t('settings.privacyBody1'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l.t('settings.privacyBody2'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l.t('settings.privacyBody3'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l.t('settings.privacyBody4'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(l.t('settings.privacyBody5'),
              style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 28),
          Text(l.t('settings.consent'),
              style: Theme.of(context).textTheme.titleSmall),
          SwitchListTile(
            title: Text(l.t('settings.locationConsent')),
            value: s.locationConsent,
            onChanged: (bool v) => sp.setLocationConsent(v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.micConsent')),
            value: s.micConsent,
            onChanged: (bool v) => sp.setMicConsent(v),
          ),
          SwitchListTile(
            title: Text(l.t('settings.photoConsent')),
            value: s.photoConsent,
            onChanged: (bool v) => sp.setPhotoConsent(v),
          ),
          SwitchListTile(
            title: Text(l.t('track.disableTracking')),
            value: s.trackingEnabled,
            onChanged: (bool v) => sp.setTrackingEnabled(v),
          ),
          const Divider(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever),
            label: Text(l.t('settings.deleteAll')),
            onPressed: () async {
              final bool? ok = await showDialog<bool>(
                context: context,
                builder: (BuildContext ctx) => AlertDialog(
                  title: Text(l.t('common.deleteTitle')),
                  content: Text(l.t('settings.deleteAllConfirm')),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.t('common.cancel')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.t('common.delete')),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await LumoraRepository.instance.wipeAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.t('settings.deleted'))),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 8),
          Text(l.t('sync.offlineNote'),
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// About & Help pages
// ---------------------------------------------------------------------

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.about'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Icon(Icons.wb_sunny,
              size: 72, color: Color(0xFF5B7FDB)),
          const SizedBox(height: 12),
          Center(
            child: Text('Lumora',
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          Center(
            child: Text(l.t('app.tagline'),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${l.t('settings.version')} ${AppConfig.appVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lumora is a communication and safety companion for '
            'specially-abled children. All demo data is fictional. '
            'Lumora does not provide medical, psychological or '
            'diagnostic services.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HelpPage extends StatelessWidget {
  const _HelpPage();

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.help'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(l.t('auth.demoAccountsBody'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(l.t('sync.offlineNote'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(l.t('common.emergencyNote'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                      color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
}
