import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/learning_activity.dart';
import '../../providers/learning_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';
import 'learning_catalog.dart';

/// Interactive learning activity player.
/// Modes: quiz (multiple choice), memory (pairs) and matching.
/// Wrong answers are never punished - the child simply retries.
class LearningActivityScreen extends StatefulWidget {
  const LearningActivityScreen({
    super.key,
    required this.activityId,
    this.mode = 'quiz',
  });

  final String activityId;
  final String mode;

  @override
  State<LearningActivityScreen> createState() =>
      _LearningActivityScreenState();
}

class _LearningActivityScreenState extends State<LearningActivityScreen> {
  List<ActivityQuestion> _questions = <ActivityQuestion>[];
  int _index = 0;
  int _correct = 0;
  int _attempts = 0;
  String? _feedback;
  final DateTime _start = DateTime.now();
  List<String> _memoryDeck = <String>[];
  final Set<int> _matched = <int>{};
  int? _firstPick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  void _setup() {
    final LearningActivity? activity = LearningCatalog.byId(widget.activityId);
    final LearningProvider learning = context.read<LearningProvider>();
    final String lang =
        context.read<SessionProvider>().child?.languageCode ?? 'en';
    if (activity == null) return;
    if (widget.mode == 'memory') {
      final List<String> bank = LearningCatalog.generateQuiz(
        activity: activity,
        level: learning.selectedLevel,
        languageCode: lang,
        count: 6,
      ).map((ActivityQuestion q) => q.answer).toList();
      _memoryDeck = <String>[...bank, ...bank]..shuffle();
    } else {
      _questions = LearningCatalog.generateQuiz(
        activity: activity,
        level: learning.selectedLevel,
        languageCode: lang,
        count: 5,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _answer(String option) async {
    final ActivityQuestion q = _questions[_index];
    setState(() => _attempts++);
    if (option == q.answer) {
      FeedbackService.success();
      setState(() {
        _correct++;
        _feedback = context.l10n.t('learn.correct');
      });
      await TtsService.instance.speak(context.l10n.t('learn.correct'));
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_index < _questions.length - 1) {
          setState(() {
            _index++;
            _feedback = null;
          });
        } else {
          _finish();
        }
      });
    } else {
      FeedbackService.error();
      setState(() =>
          _feedback = context.l10n.t('learn.tryAgain'));
      await TtsService.instance.speak(context.l10n.t('learn.tryAgain'));
    }
  }

  void _memoryPick(int i) {
    if (_matched.contains(i)) return;
    if (_firstPick == null) {
      setState(() => _firstPick = i);
      return;
    }
    if (_firstPick == i) {
      setState(() => _firstPick = null);
      return;
    }
    final bool match = _memoryDeck[_firstPick!] == _memoryDeck[i];
    FeedbackService.tap();
    setState(() {
      if (match) {
        _matched.addAll(<int>{_firstPick!, i});
        _correct++;
        _attempts++;
      } else {
        _attempts++;
      }
      _firstPick = null;
    });
    if (_matched.length == _memoryDeck.length) _finish();
  }

  Future<void> _finish() async {
    final AppL10n l = context.l10n;
    final LearningProvider learning = context.read<LearningProvider>();
    final SessionProvider session = context.read<SessionProvider>();
    final LearningActivity? activity = LearningCatalog.byId(widget.activityId);
    if (activity != null && session.child != null) {
      await learning.recordResult(
        childId: session.child!.id,
        activity: activity,
        correct: _correct,
        total: widget.mode == 'memory'
            ? (_memoryDeck.length ~/ 2)
            : _questions.length,
        durationSeconds: DateTime.now().difference(_start).inSeconds,
      );
    }
    if (!mounted) return;
    await TtsService.instance.speak(l.t('learn.complete'));
    if (mounted) setState(() => _feedback = l.t('learn.complete'));
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LearningActivity? activity = LearningCatalog.byId(widget.activityId);
    if (activity == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorView(message: 'Activity not found'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t(activity.titleKey)),
        actions: const <Widget>[SignOutButton()],
      ),
      body: SafeArea(
        child: _feedback == l.t('learn.complete')
            ? _buildComplete(context)
            : _buildPlay(context),
      ),
    );
  }

  Widget _buildComplete(BuildContext context) {
    final AppL10n l = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.emoji_events,
              size: 96, color: AppColors.yellow),
          const SizedBox(height: 16),
          Text(l.t('learn.complete'),
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('${l.t('learn.stars')}: '
              '${(_correct * 3 / (_attempts == 0 ? 1 : _attempts)).round().clamp(0, 3)} / 3'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                icon: const Icon(Icons.replay),
                label: Text(l.t('learn.retry')),
                onPressed: () {
                  setState(() {
                    _index = 0;
                    _correct = 0;
                    _attempts = 0;
                    _feedback = null;
                    _matched.clear();
                    _firstPick = null;
                    _memoryDeck = <String>[];
                  });
                  _setup();
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l.t('common.done')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlay(BuildContext context) {
    final AppL10n l = context.l10n;
    if (widget.mode == 'memory') return _buildMemory(context);

    if (_questions.isEmpty) return const LoadingView();

    final ActivityQuestion q = _questions[_index];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Text('${l.t('learn.question')} ${_index + 1} ${l.t('learn.of')} '
                '${_questions.length}'),
            const Spacer(),
            IconButton(
              tooltip: l.t('learn.audioInstructions'),
              icon: const Icon(Icons.volume_up),
              onPressed: () =>
                  TtsService.instance.speak(q.speakText ?? q.answer),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          q.answer,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 20),
        ...q.options.map(
          (String option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 64,
              child: FilledButton.tonal(
                onPressed: () => _answer(option),
                child: Text(option,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
          ),
        ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _feedback!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _feedback == l.t('learn.correct')
                        ? AppColors.success
                        : AppColors.orange,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildMemory(BuildContext context) {
    final AppL10n l = context.l10n;
    if (_memoryDeck.isEmpty) return const LoadingView();
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(l.t('learn.memory'),
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _memoryDeck.length,
            itemBuilder: (BuildContext context, int i) {
              final bool revealed =
                  _matched.contains(i) || _firstPick == i;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _memoryPick(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: revealed
                        ? AppColors.teal.withValues(alpha: 0.3)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    revealed ? _memoryDeck[i] : '?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
