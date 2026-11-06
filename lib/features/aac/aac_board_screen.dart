import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/speech/tts_service.dart';
import '../../core/utilities/feedback_service.dart';
import '../../widgets/barrel.dart';
import '../../widgets/sign_out_button.dart';

/// The AAC picture board for one category (or Favorites).
/// Tap a card to hear it and add it to the sentence strip; the strip can be
/// spoken, saved, or cleared. Fully offline.
class AacBoardScreen extends StatefulWidget {
  const AacBoardScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<AacBoardScreen> createState() => _AacBoardScreenState();
}

class _AacBoardScreenState extends State<AacBoardScreen> {
  final List<PictureCard> _sentence = <PictureCard>[];

  void _onCardTap(PictureCard card) {
    final String lang =
        context.read<SessionProvider>().child?.languageCode ?? 'en';
    final String label = card.label(lang);

    FeedbackService.tap();
    TtsOrAudio.speakCard(card, label);

    setState(() => _sentence.add(card));

    final SessionProvider session = context.read<SessionProvider>();
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final String childId = session.child?.id ?? 'unknown';
    comm.logAttempt(
      childId: childId,
      method: CommMethod.aac,
      content: label,
    );
  }

  Future<void> _speakSentence() async {
    if (_sentence.isEmpty) return;
    final String lang =
        context.read<SessionProvider>().child?.languageCode ?? 'en';
    final SessionProvider session = context.read<SessionProvider>();
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final String text = _sentence.map((PictureCard c) => c.label(lang)).join(' ');
    await TtsService.instance.speak(text);
    final String childId = session.child?.id ?? 'unknown';
    await comm.logAttempt(
      childId: childId,
      method: CommMethod.aac,
      content: text,
    );
    await comm.saveSentence(childId, _sentence.map((PictureCard c) => c.label(lang)).toList());
  }

  Future<void> _saveSentence() async {
    if (_sentence.isEmpty) return;
    final String lang =
        context.read<SessionProvider>().child?.languageCode ?? 'en';
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final SessionProvider session = context.read<SessionProvider>();
    await comm.saveSentence(
      session.child?.id ?? 'unknown',
      _sentence.map((PictureCard c) => c.label(lang)).toList(),
    );
    FeedbackService.confirm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('aac.sentenceSaved'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final String lang = session.child?.languageCode ?? 'en';
    final CommunicationProvider comm = context.watch<CommunicationProvider>();

    final bool isFavorites = widget.categoryId == 'favorites';
    final LumoraRepository repo = LumoraRepository.instance;
    final PictureCategory? category =
        isFavorites ? null : repo.getCategory(widget.categoryId);
    final List<PictureCard> cards = isFavorites
        ? repo.getFavoriteCards()
        : repo.getCardsForCategory(widget.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isFavorites ? l.t('aac.favoritesCat') : category?.name(lang) ?? ''),
      actions: <Widget>[
        const SignOutButton(),
      ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: SentenceStrip(
                words: _sentence,
                languageCode: lang,
                onRemoveAt: (int i) =>
                    setState(() => _sentence.removeAt(i)),
                onClear: () => setState(_sentence.clear),
                onSpeak: _speakSentence,
                onSave: _saveSentence,
                emptyLabel: l.t('aac.sentence'),
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? EmptyView(
                      title: l.t('aac.boardEmpty'),
                      icon: Icons.grid_view,
                      actionLabel: session.isParent
                          ? l.t('aac.addCard')
                          : null,
                      onAction: session.isParent
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Manage cards from Parent Dashboard → '
                                        'Content management.')),
                              )
                          : null,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 140,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (BuildContext context, int i) {
                        final PictureCard card = cards[i];
                        return AacCardTile(
                          card: card,
                          languageCode: lang,
                          onTap: () => _onCardTap(card),
                          onToggleFavorite: () async {
                            await repo.saveCard(
                              card.copyWith(isFavorite: !card.isFavorite),
                            );
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
            // Speaking indicator for accessibility feedback.
            if (comm.activities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${l.t('track.attempts')}: ${comm.activities.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Plays custom audio when present, falls back to TTS.
class TtsOrAudio {
  static Future<void> speakCard(PictureCard card, String fallbackText) async {
    if (card.customAudioPath != null) {
      final bool played =
          await AudioPlayerService.instance.play(card.customAudioPath!);
      if (played) return;
    }
    await TtsService.instance.speak(card.speechText ?? fallbackText);
  }
}
