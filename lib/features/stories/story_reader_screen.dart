import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../data/demo/demo_data.dart';
import '../../widgets/barrel.dart';
import '../../models/story.dart';
import '../../services/speech/tts_service.dart';

/// Story reader with big prev/next buttons, repeat, narration, and simple
/// choice interactions. Audio narration uses TTS until a caregiver records
/// a custom track for a page.
class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({super.key, required this.storyId});

  final String storyId;

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  int _page = 0;
  Story? _story;

  @override
  void initState() {
    super.initState();
    _story = _find();
  }

  Story? _find() {
    for (final Story s in DemoData.stories) {
      if (s.id == widget.storyId) return s;
    }
    return null;
  }

  StoryPage get _current => _story!.pages[_page];

  Future<void> _speakPage() async {
    await TtsService.instance.speak(_current.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final Story? story = _story;

    if (story == null || story.pages.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(
          title: l.t('common.empty'),
          icon: Icons.auto_stories,
        ),
      );
    }

    final StoryPage page = story.pages[_page];
    final Color color = AppColors.fromName(page.colorName);
    final bool isLast = _page == story.pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(story.title),
        actions: <Widget>[
          SignOutButton(),
          IconButton(
            tooltip: l.t('common.repeat'),
            icon: const Icon(Icons.replay),
            onPressed: _speakPage,
          ),
          IconButton(
            tooltip: l.t('story.narration'),
            icon: const Icon(Icons.volume_up),
            onPressed: _speakPage,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Text(
                '${l.t('story.page')} ${_page + 1} / ${story.pages.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(IconCatalog.of(page.iconKey),
                        size: 84, color: color),
                    const SizedBox(height: 18),
                    Text(
                      page.text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              if (page.choices.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(l.t('story.choices'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: page.choices
                      .map(
                        (StoryChoice c) => FilledButton.tonal(
                          onPressed: () async {
                            FeedbackService.tap();
                            final int next = story.pages
                                .indexWhere((StoryPage p) => p.id == c.nextPageId);
                            if (next >= 0) {
                              setState(() => _page = next);
                              await _speakPage();
                            }
                          },
                          child: Text(c.text),
                        ),
                      )
                      .toList(),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l.t('story.prev')),
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                  ),
                  FilledButton.icon(
                    icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                    label: Text(isLast ? l.t('common.done') : l.t('story.next')),
                    onPressed: () async {
                      if (isLast) {
                        Navigator.of(context).maybePop();
                        return;
                      }
                      setState(() => _page++);
                      await _speakPage();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


