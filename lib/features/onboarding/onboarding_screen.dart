import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';

/// Onboarding pager: explains communication support, AAC, learning,
/// routines, emotions, safety and the parent dashboard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<({String key, IconData icon, String color})> _pages =
      <({String key, IconData icon, String color})>[
    (key: 'p1', icon: Icons.record_voice_over, color: 'blue'),
    (key: 'p2', icon: Icons.grid_view, color: 'purple'),
    (key: 'p3', icon: Icons.extension, color: 'teal'),
    (key: 'p4', icon: Icons.checklist, color: 'yellow'),
    (key: 'p5', icon: Icons.sentiment_satisfied, color: 'orange'),
    (key: 'p6', icon: Icons.shield, color: 'red'),
    (key: 'p7', icon: Icons.dashboard, color: 'blue'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      if (mounted) unawaited(context.push('/role-select'));
    }
  }

  Future<void> _speakPage() async {
    final AppL10n l = context.l10n;
    await TtsService.instance.speak(
      '${l.t('onboarding.${_pages[_page].key}Title')}. '
      '${l.t('onboarding.${_pages[_page].key}Body')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final TextTheme t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(        actions: <Widget>[
          SignOutButton(),
          TextButton(
            onPressed: () => context.push('/role-select'),
            child: Text(l.t('onboarding.skip')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (int i) => setState(() => _page = i),
                itemBuilder: (BuildContext context, int index) {
                  final p = _pages[index];
                  final Color color = AppColors.fromName(p.color);
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon, size: 64, color: color),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          l.t('onboarding.${p.key}Title'),
                          textAlign: TextAlign.center,
                          style: t.headlineMedium,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l.t('onboarding.${p.key}Body'),
                          textAlign: TextAlign.center,
                          style: t.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        IconButton(
                          tooltip: l.t('story.narration'),
                          onPressed: _speakPage,
                          icon: const Icon(Icons.volume_up, size: 32),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                _pages.length,
                (int i) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == _pages.length - 1
                        ? l.t('common.continue')
                        : l.t('common.next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
