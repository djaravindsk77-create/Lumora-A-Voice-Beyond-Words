import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/child_profile.dart';
import '../../models/communication_activity.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';

/// My Needs: large quick-action cards. Each tap displays the phrase, plays
/// audio, offers repetition, optionally notifies a caregiver, and logs the
/// attempt to communication history.
class MyNeedsScreen extends StatelessWidget {
  const MyNeedsScreen({super.key});

  static const List<({String id, String en, String ta, IconData icon, String color})>
      _needs = <({String id, String en, String ta, IconData icon, String color})>[
    (id: 'hungry', en: 'I am hungry', ta: 'எனக்கு பசிக்கிறது', icon: Icons.restaurant, color: 'orange'),
    (id: 'thirsty', en: 'I am thirsty', ta: 'எனக்கு தாகம்', icon: Icons.local_drink, color: 'teal'),
    (id: 'bathroom', en: 'I need the bathroom', ta: 'கழிவறை வேண்டும்', icon: Icons.wc, color: 'blue'),
    (id: 'tired', en: 'I am tired', ta: 'எனக்கு சோர்வு', icon: Icons.bedtime, color: 'purple'),
    (id: 'pain', en: 'I am in pain', ta: 'எனக்கு வலி', icon: Icons.healing, color: 'red'),
    (id: 'help', en: 'I need help', ta: 'எனக்கு உதவி வேண்டும்', icon: Icons.front_hand, color: 'orange'),
    (id: 'sleep', en: 'I want to sleep', ta: 'தூங்க வேண்டும்', icon: Icons.hotel, color: 'purple'),
    (id: 'play', en: 'I want to play', ta: 'விளையாட வேண்டும்', icon: Icons.toys, color: 'yellow'),
    (id: 'outside', en: 'I want to go outside', ta: 'வெளியே செல்ல வேண்டும்', icon: Icons.park, color: 'green'),
    (id: 'goHome', en: 'I want to go home', ta: 'வீட்டுக்கு போக வேண்டும்', icon: Icons.home, color: 'blue'),
    (id: 'break', en: 'I need a break', ta: 'எனக்கு ஓய்வு வேண்டும்', icon: Icons.self_improvement, color: 'teal'),
    (id: 'uncomfortable', en: 'I feel uncomfortable', ta: 'எனக்கு சங்கடமாக இருக்கிறது', icon: Icons.sentiment_neutral, color: 'orange'),
    (id: 'parent', en: 'I need my parent', ta: 'என் பெற்றோர் வேண்டும்', icon: Icons.family_restroom, color: 'pink'),
    (id: 'understand', en: 'I do not understand', ta: 'எனக்கு புரியவில்லை', icon: Icons.help, color: 'gray'),
  ];

  Future<void> _onNeed(BuildContext context, _Need n) async {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.read<SessionProvider>();
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final SettingsProvider settingsProvider = context.read<SettingsProvider>();
    final String lang = session.child?.languageCode ?? 'en';
    final String phrase = lang == 'ta' ? n.ta : n.en;
    final String childId = session.child?.id ?? 'unknown';

    FeedbackService.tap();
    await TtsService.instance.speak(phrase);

    await comm.logAttempt(
      childId: childId,
      method: CommMethod.needs,
      content: phrase,
    );

    // Notify caregiver when the parent enabled notifications for this need.
    final ChildProfile? child = session.child;
    final bool shouldNotify = child?.notifiedNeedIds.contains(n.id) ?? false;
    if (shouldNotify) {
      await NotificationService.instance.notify(
        type: 'alert',
        title: l.t('needs.title'),
        body: phrase,
        settings: settingsProvider.settings,
        force: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.t('needs.sent'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final String lang =
        context.watch<SessionProvider>().child?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('needs.title')),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 128,
                ),
                itemCount: _needs.length,
                itemBuilder: (BuildContext context, int i) {
                  final _Need n = _needs[i];
                  final Color color = AppColors.fromName(n.color);
                  final String phrase = lang == 'ta' ? n.ta : n.en;
                  return Semantics(
                    button: true,
                    label: phrase,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onNeed(context, n),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.45)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(n.icon, size: 42, color: color),
                            const SizedBox(height: 8),
                            Text(
                              phrase,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l.t('needs.custom'),
                  style: Theme.of(context).textTheme.labelSmall),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data shape for a quick-need card (matches the record literal in `_needs`).
typedef _Need = ({String id, String en, String ta, IconData icon, String color});
