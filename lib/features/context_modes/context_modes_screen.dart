import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/barrel.dart';
import '../../widgets/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/speech/tts_service.dart';

/// Context-Aware Communication Modes: Home, School, Hospital, Travel,
/// Public Places, Playground, Mealtime, Classroom, Therapy, Bedtime.
/// Manual switching only (no silent location detection); suggestions can
/// be disabled by the parent.
class ContextModesScreen extends StatelessWidget {
  const ContextModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final CommunicationProvider comm = context.watch<CommunicationProvider>();
    final SettingsProvider sp = context.watch<SettingsProvider>();
    final SessionProvider session = context.watch<SessionProvider>();
    final String current = comm.contextMode;
    final CommunicationMode? mode = ModeCatalog.byId(current);

    final List<CommunicationMode> modes = ModeCatalog.builtIn
        .where((CommunicationMode m) =>
            m.enabled &&
            (session.child?.enabledModes.contains(m.id) ?? true))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('modes.title')),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.t('modes.current'),
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          IconCatalog.of(mode?.iconKey ?? 'home'),
                          color: AppColors.fromName(mode?.colorName ?? 'blue'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mode == null
                                ? '-'
                                : l.t(mode.nameKey),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    if (sp.settings.modeSuggestionsEnabled) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        l.t('modes.enableSuggestions'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: modes.length,
                itemBuilder: (BuildContext context, int i) {
                  final CommunicationMode m = modes[i];
                  final Color color = AppColors.fromName(m.colorName);
                  final bool selected = m.id == current;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        FeedbackService.tap();
                        comm.setContextMode(m.id);
                      },
                      child: Container(
                        width: 104,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: selected ? 0.3 : 0.13),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.4),
                            width: selected ? 2.2 : 1.1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(IconCatalog.of(m.iconKey),
                                size: 34, color: color),
                            const SizedBox(height: 6),
                            Text(
                              l.t(m.nameKey),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style:
                                  Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(l.t('modes.phrases'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (mode == null || mode.phrases.isEmpty)
              Text(l.t('modes.noPhrases'),
                  style: Theme.of(context).textTheme.bodySmall)
            else
              ...mode.phrases.map(
                (String phrase) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(phrase),
                    trailing: const Icon(Icons.volume_up),
                    onTap: () async {
                      FeedbackService.tap();
                      await TtsService.instance.speak(phrase);
                      await comm.logAttempt(
                        childId: session.child?.id ?? 'unknown',
                        method: CommMethod.needs,
                        content: phrase,
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'A grown-up can add custom modes and phrases from the Parent '
              'Dashboard. Location is never used to detect modes.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
