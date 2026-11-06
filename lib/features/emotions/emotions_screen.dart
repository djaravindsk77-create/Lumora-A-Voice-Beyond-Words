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
import '../../repositories/lumora_repository.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/speech/tts_service.dart';

/// Emotions & Feelings module.
/// Child picks an emotion, hears it, optionally picks a comfort action or
/// asks for a break / caregiver. Entries are stored (never interpreted) and
/// caregivers are notified only for parent-enabled emotions.
class EmotionsScreen extends StatefulWidget {
  const EmotionsScreen({super.key});

  @override
  State<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends State<EmotionsScreen> {
  String? _selected;
  bool _showComfort = false;

  Future<void> _select(String emotionId) async {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.read<SessionProvider>();
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final String childId = session.child?.id ?? 'unknown';

    FeedbackService.tap();
    setState(() {
      _selected = emotionId;
      _showComfort = true;
    });

    await TtsService.instance.speak(l.t('emo.$emotionId'));
    await comm.logAttempt(
      childId: childId,
      method: CommMethod.emotions,
      content: l.t('emo.$emotionId'),
    );
  }

  Future<void> _comfort(String? comfortId) async {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.read<SessionProvider>();
    final SettingsProvider sp = context.read<SettingsProvider>();
    final LumoraRepository repo = LumoraRepository.instance;
    final String childId = session.child?.id ?? 'unknown';
    final String emotionId = _selected ?? 'happy';

    // Notify only for emotions the parent enabled.
    final ChildProfile? child = session.child;
    final bool notify =
        child?.notifiedEmotionIds.contains(emotionId) ?? false;

    await repo.saveEmotionEntry(EmotionEntry(
      id: repo.local.newId(),
      childId: childId,
      emotionId: emotionId,
      comfortChoiceId: comfortId,
      notifiedCaregiver: notify,
      createdAt: DateTime.now(),
    ));

    if (notify) {
      await NotificationService.instance.notify(
        type: 'alert',
        title: l.t('feel.title'),
        body: l.t('emo.$emotionId'),
        settings: sp.settings,
        force: true,
      );
    }

    if (comfortId == 'break') {
      await TtsService.instance.speak(l.t('feel.needBreak'));
    } else if (comfortId == 'call') {
      await TtsService.instance.speak(l.t('feel.callCaregiver'));
    }

    FeedbackService.confirm();
    if (mounted) {
      setState(() {
        _selected = null;
        _showComfort = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('feel.saved'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('feel.title')),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    l.t('feel.question'),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 116,
                    ),
                    itemCount: EmotionCatalog.ids.length,
                    itemBuilder: (BuildContext context, int i) {
                      final String id = EmotionCatalog.ids[i];
                      final Color color =
                          AppColors.fromName(EmotionCatalog.colorName(id));
                      final bool selected = _selected == id;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: l.t('emo.$id'),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _select(id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(
                                  alpha: selected ? 0.32 : 0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? color : color.withValues(alpha: 0.4),
                                width: selected ? 2.5 : 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  IconCatalog.of(EmotionCatalog.iconKey(id)),
                                  size: 40,
                                  color: color,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l.t('emo.$id'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_showComfort) ...<Widget>[
                    const SizedBox(height: 20),
                    Text(
                      l.t('feel.comfort'),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        for (final String c in EmotionCatalog.comfortChoiceIds)
                          FilledButton.tonal(
                            onPressed: () => _comfort(c),
                            child: Text(_comfortLabel(context, c)),
                          ),
                        FilledButton(
                          onPressed: () => _comfort('break'),
                          child: Text(l.t('feel.needBreak')),
                        ),
                        OutlinedButton(
                          onPressed: () => _comfort('call'),
                          child: Text(l.t('feel.callCaregiver')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.t('feel.notifyNote'),
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _comfortLabel(BuildContext context, String id) {
    final AppL10n l = context.l10n;
    switch (id) {
      case 'hug':
        return l.t('feel.comfortHug');
      case 'quiet':
        return l.t('feel.comfortQuiet');
      case 'music':
        return l.t('feel.comfortMusic');
      case 'talk':
        return l.t('feel.comfortTalk');
      default:
        return l.t('feel.comfortBreak');
    }
  }
}
