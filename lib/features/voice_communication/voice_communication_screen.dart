import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/communication_activity.dart';
import '../../models/phrase.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/speech/speech_to_text_service.dart';
import '../../services/speech/tts_service.dart';

/// Voice Communication module: type or dictate, then speak aloud with
/// adjustable rate/volume. Saved, recent and favourite phrases are available
/// offline. STT failure degrades to text input with a friendly notice.
class VoiceCommunicationScreen extends StatefulWidget {
  const VoiceCommunicationScreen({super.key});

  @override
  State<VoiceCommunicationScreen> createState() =>
      _VoiceCommunicationScreenState();
}

class _VoiceCommunicationScreenState extends State<VoiceCommunicationScreen> {
  final TextEditingController _text = TextEditingController();
  final SpeechToTextService _stt = SpeechToTextService.instance;
  bool _sttReady = false;
  bool _listening = false;
  double _rate = 0.45;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final bool ready = await _stt.init();
    if (mounted) setState(() => _sttReady = ready);
  }

  Future<void> _speak(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await TtsService.instance.setRate(_rate);
    await TtsService.instance.setVolume(_volume);
    await TtsService.instance.speak(trimmed);
    if (!mounted) return;
    final SessionProvider session = context.read<SessionProvider>();
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final String childId = session.child?.id ?? 'unknown';
    await comm.savePhrase(childId, trimmed);
    await comm.logAttempt(
      childId: childId,
      method: CommMethod.voice,
      content: trimmed,
    );
  }

  Future<void> _toggleListening() async {
    if (!_sttReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('voice.sttUnavailable'))),
      );
      return;
    }
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    final PermissionService permissions = PermissionService.instance;
    await permissions.requestMicrophone();
    if (!mounted) return;
    final String lang =
        context.read<SettingsProvider>().settings.languageCode;
    final bool ok = await _stt.listen(
      onResult: (String text) {
        if (mounted) setState(() => _text.text = text);
      },
      languageCode: lang,
    );
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('voice.sttUnavailable'))),
        );
      }
      return;
    }
    setState(() => _listening = true);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final CommunicationProvider comm = context.watch<CommunicationProvider>();
    final List<SavedPhrase> saved = comm.phrases;
    final List<SavedPhrase> favorites =
        saved.where((SavedPhrase p) => p.isFavorite).toList();
    final List<SavedPhrase> recent = saved
        .where((SavedPhrase p) => p.lastUsedAt != null)
        .toList()
      ..sort((SavedPhrase a, SavedPhrase b) =>
          b.lastUsedAt!.compareTo(a.lastUsedAt!));

    return Scaffold(
      appBar: AppBar(title: Text(l.t('voice.title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _text,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l.t('voice.hint'),
                suffixIcon: IconButton(
                  tooltip: _sttReady
                      ? l.t('voice.listen')
                      : l.t('voice.sttUnavailable'),
                  icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                      color: _listening
                          ? Theme.of(context).colorScheme.error
                          : null),
                  onPressed: _toggleListening,
                ),
              ),
              onSubmitted: _speak,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.volume_up),
                    label: Text(l.t('common.speak')),
                    onPressed: () => _speak(_text.text),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.t('common.repeat'),
                  icon: const Icon(Icons.replay),
                  onPressed: () => _speak(_text.text),
                ),
                IconButton(
                  tooltip: l.t('common.stop'),
                  icon: const Icon(Icons.stop),
                  onPressed: () => TtsService.instance.stop(),
                ),
                IconButton(
                  tooltip: l.t('common.clear'),
                  icon: const Icon(Icons.backspace),
                  onPressed: () => setState(() => _text.clear()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.t('voice.speed'),
                style: Theme.of(context).textTheme.labelMedium),
            Slider(
              value: _rate,
              min: 0.2,
              max: 0.9,
              divisions: 7,
              label: _rate.toStringAsFixed(1),
              onChanged: (double v) => setState(() => _rate = v),
            ),
            Text(l.t('voice.volume'),
                style: Theme.of(context).textTheme.labelMedium),
            Slider(
              value: _volume,
              min: 0.2,
              max: 1.0,
              divisions: 8,
              label: _volume.toStringAsFixed(1),
              onChanged: (double v) => setState(() => _volume = v),
            ),
            const SizedBox(height: 8),
            Text(l.t('voice.savedPhrases'),
                style: Theme.of(context).textTheme.titleMedium),
            if (saved.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.t('voice.noSaved'),
                    style: Theme.of(context).textTheme.bodySmall),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: saved
                    .take(10)
                    .map(
                      (SavedPhrase p) => InputChip(
                        label: Text(p.text),
                        avatar: Icon(
                          p.isFavorite ? Icons.star : Icons.record_voice_over,
                          size: 18,
                        ),
                        onPressed: () => _speak(p.text),
                        onDeleted: favorites.contains(p)
                            ? null
                            : () => comm.deletePhrase(p),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            Text(l.t('voice.favorites'),
                style: Theme.of(context).textTheme.titleMedium),
            if (favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.t('voice.noFavorites'),
                    style: Theme.of(context).textTheme.bodySmall),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: favorites
                    .map(
                      (SavedPhrase p) => InputChip(
                        label: Text(p.text),
                        avatar: const Icon(Icons.star, size: 18),
                        onPressed: () => _speak(p.text),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            Text(l.t('voice.recent'),
                style: Theme.of(context).textTheme.titleMedium),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l.t('voice.noRecent'),
                    style: Theme.of(context).textTheme.bodySmall),
              )
            else
              Column(
                children: recent
                    .take(5)
                    .map(
                      (SavedPhrase p) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.history),
                        title: Text(p.text),
                        onTap: () => _speak(p.text),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
