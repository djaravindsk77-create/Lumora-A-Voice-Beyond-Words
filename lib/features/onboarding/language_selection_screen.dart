
import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../services/speech/tts_service.dart';

/// Language selection (English / Tamil / Malayalam / Hindi), persisted and
/// applied globally.
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key, this.role});

  final String? role;

  static const List<Locale> all = <Locale>[
    AppLocales.english,
    AppLocales.tamil,
    AppLocales.malayalam,
    AppLocales.hindi,
  ];

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final String current = settings.settings.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('onboarding.languageTitle'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Text(
                l.t('onboarding.languageSubtitle'),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...all.map(
                (Locale locale) {
                  final String code = AppLocales.code(locale);
                  final bool selected = current == code;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        selected: selected,
                        onTap: () async {
                          await settings.setLanguage(code);
                          await TtsService.instance.applyLanguage(code);
                          if (context.mounted) {
                            unawaited(
                              context.push(
                                '/accessibility?role=${role ?? 'child'}',
                              ),
                            );
                          }
                        },
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(
                          AppLocales.displayName(locale),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(AppLocales.languageName(code)),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
