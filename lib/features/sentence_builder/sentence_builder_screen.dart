import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/ai/suggestion_engine.dart';
import '../../services/speech/tts_service.dart';
import '../../core/utilities/feedback_service.dart';

/// Sentence Builder: tap word tiles to compose a sentence (I → want →
/// water). Supports reorder, remove, clear, speak, save, templates,
/// history and rule-based frequent suggestions.
class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final List<String> _words = <String>[];
  final TextEditingController _custom = TextEditingController();

  static const List<List<String>> _templates = <List<String>>[
    <String>['I', 'want'],
    <String>['I', 'need'],
    <String>['I', 'feel'],
    <String>['I', 'do', 'not', 'want'],
    <String>['Can', 'you', 'help', 'me'],
  ];

  Future<void> _speakAndLog() async {
    if (_words.isEmpty) return;
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final SessionProvider session = context.read<SessionProvider>();
    final String text = _words.join(' ');
    await TtsService.instance.speak(text);
    final String childId = session.child?.id ?? 'unknown';
    await comm.logAttempt(
      childId: childId,
      method: CommMethod.sentenceBuilder,
      content: text,
    );
    await comm.saveSentence(childId, List<String>.from(_words));
  }

  Future<void> _save() async {
    if (_words.isEmpty) return;
    final CommunicationProvider comm = context.read<CommunicationProvider>();
    final SessionProvider session = context.read<SessionProvider>();
    await comm.saveSentence(
        session.child?.id ?? 'unknown', List<String>.from(_words));
    FeedbackService.confirm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('aac.sentenceSaved'))),
      );
    }
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final CommunicationProvider comm = context.watch<CommunicationProvider>();
    final List<String> suggestions = SuggestionEngine.instance
        .predictNextWords(comm.sentenceHistory, count: 8);
    final List<SentenceHistory> history = comm.sentenceHistory;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('sb.title'))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _words.isEmpty
                                ? l.t('sb.title')
                                : _words.join(' '),
                            style:
                                Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove last',
                          icon: const Icon(Icons.backspace),
                          onPressed: _words.isEmpty
                              ? null
                              : () => setState(
                                  () => _words.removeLast()),
                        ),
                        IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.delete_sweep),
                          onPressed: _words.isEmpty
                              ? null
                              : () => setState(_words.clear),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.bookmark_add),
                          label: Text(l.t('sb.saveFavorite')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _speakAndLog,
                          icon: const Icon(Icons.volume_up),
                          label: Text(l.t('common.speak')),
                        ),
                      ],
                    ),
                    if (_words.length > 1)
                      Wrap(
                        spacing: 6,
                        children: List<Widget>.generate(_words.length, (int i) {
                          return ActionChip(
                            label: Text('${i + 1}. ${_words[i]}'),
                            onPressed: () {
                              // Move word earlier on tap.
                              setState(() {
                                if (i > 0) {
                                  final String w = _words.removeAt(i);
                                  _words.insert(i - 1, w);
                                }
                              });
                            },
                          );
                        }),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _custom,
                      decoration: const InputDecoration(
                        hintText: 'Add your own word',
                        isDense: true,
                      ),
                      onSubmitted: (String v) {
                        if (v.trim().isNotEmpty) {
                          setState(() {
                            _words.add(v.trim());
                            _custom.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      if (_custom.text.trim().isNotEmpty) {
                        setState(() {
                          _words.add(_custom.text.trim());
                          _custom.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                  Text(l.t('sb.templates'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _templates
                        .map((List<String> t) => ActionChip(
                              label: Text(t.join(' ')),
                              onPressed: () =>
                                  setState(() => _words.addAll(t)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(l.t('sb.frequent'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                        .map((String w) => ActionChip(
                              label: Text(w),
                              onPressed: () =>
                                  setState(() => _words.add(w)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(l.t('sb.history'),
                      style: Theme.of(context).textTheme.titleMedium),
                  if (history.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l.t('sb.noHistory'),
                          style: Theme.of(context).textTheme.bodySmall),
                    )
                  else
                    ...history.take(6).map(
                          (SentenceHistory s) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.history),
                            title: Text(s.spokenText),
                            subtitle: s.isFavorite
                                ? const Icon(Icons.star,
                                    size: 16, color: Colors.amber)
                                : null,
                            onTap: () {
                              setState(() {
                                _words
                                  ..clear()
                                  ..addAll(s.words);
                              });
                            },
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
