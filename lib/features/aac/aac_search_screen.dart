import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';

/// Searches every AAC card by label (English or Tamil) and speaks the
/// result when tapped. Offline-friendly.
class AacSearchScreen extends StatefulWidget {
  const AacSearchScreen({super.key});

  @override
  State<AacSearchScreen> createState() => _AacSearchScreenState();
}

class _AacSearchScreenState extends State<AacSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final String lang =
        context.watch<SessionProvider>().child?.languageCode ?? 'en';
    final LumoraRepository repo = LumoraRepository.instance;
    final List<PictureCard> all = repo.getAllCards();
    final String q = _query.trim().toLowerCase();
    final List<PictureCard> results = q.isEmpty
        ? all.take(20).toList()
        : all
            .where((PictureCard c) =>
                c.labelEn.toLowerCase().contains(q) ||
                (c.labelTa ?? '').toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('aac.searchCards'))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.t('aac.searchCards'),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (String v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? EmptyView(
                      title: l.t('aac.noCards'),
                      subtitle: l.t('aac.noCardsBody'),
                      icon: Icons.search_off,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 140,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: results.length,
                      itemBuilder: (BuildContext context, int i) =>
                          AacCardTile(
                        card: results[i],
                        languageCode: lang,
                        onTap: () => TtsService.instance
                            .speak(results[i].label(lang)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
