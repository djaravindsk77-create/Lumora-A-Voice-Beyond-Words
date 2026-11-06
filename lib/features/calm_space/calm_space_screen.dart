import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';
import '../../widgets/sign_out_button.dart';

/// Calm Space: a sensory-friendly area with a breathing guide, gentle
/// animation, colouring and calm sounds. Sound, movement and vibration can
/// be disabled inline, and the Exit button is always visible.
class CalmSpaceScreen extends StatefulWidget {
  const CalmSpaceScreen({super.key});

  @override
  State<CalmSpaceScreen> createState() => _CalmSpaceScreenState();
}

enum _Phase { idle, breatheIn, hold, breatheOut }

class _CalmSpaceScreenState extends State<CalmSpaceScreen> {
  _Phase _phase = _Phase.idle;
  int _countdown = 4;
  Timer? _timer;
  bool _soundOn = false;
  bool _movementOn = true;
  bool _vibrationOn = true;
  final List<Offset?> _colorStrokes = <Offset?>[];
  Color _brush = AppColors.teal;

  static const List<Color> _palette = <Color>[
    AppColors.teal,
    AppColors.primary,
    AppColors.secondary,
    AppColors.yellow,
  ];

  void _startBreathing() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.breatheIn;
      _countdown = 4;
    });
    _speakPhase();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          switch (_phase) {
            case _Phase.breatheIn:
              _phase = _Phase.hold;
              break;
            case _Phase.hold:
              _phase = _Phase.breatheOut;
              break;
            case _Phase.breatheOut:
              _phase = _Phase.breatheIn;
              break;
            case _Phase.idle:
              _phase = _Phase.breatheIn;
              break;
          }
          _countdown = 4;
          _speakPhase();
        }
      });
      if (_vibrationOn) FeedbackService.tap();
    });
  }

  void _speakPhase() {
    if (!_soundOn) return;
    final AppL10n l = context.l10n;
    switch (_phase) {
      case _Phase.breatheIn:
        TtsService.instance.speak(l.t('calm.breatheIn'));
        break;
      case _Phase.hold:
        TtsService.instance.speak(l.t('calm.hold'));
        break;
      case _Phase.breatheOut:
        TtsService.instance.speak(l.t('calm.breatheOut'));
        break;
      case _Phase.idle:
        break;
    }
  }

  void _stopBreathing() {
    _timer?.cancel();
    setState(() => _phase = _Phase.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBackground
              : AppColors.tealLight,
      appBar: AppBar(
        title: Text(l.t('calm.title')),
        actions: <Widget>[
          IconButton(
            tooltip: l.t('calm.settings'),
            icon: const Icon(Icons.tune),
            onPressed: _showCalmSettings,
          ),
          const SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            DemoBanner(text: l.t('calm.intro')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _breathingCard(context),
                  const SizedBox(height: 16),
                  _coloringCard(context),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.music_note),
                        label: Text(l.t('calm.music')),
                        onPressed: () => TtsService.instance
                            .speak('Playing calm music (demo)'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.forest),
                        label: Text(l.t('calm.nature')),
                        onPressed: () => TtsService.instance
                            .speak('Playing nature sounds (demo)'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.self_improvement),
                        label: Text(l.t('calm.relax')),
                        onPressed: () => TtsService.instance
                            .speak('Relax your hands, shoulders and breath'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.front_hand),
                        label: Text(l.t('calm.break')),
                        onPressed: () => TtsService.instance
                            .speak(context.l10n.t('feel.needBreak')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Immediate exit always visible.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.exit_to_app),
              label: Text(l.t('calm.exit'),
                  style: Theme.of(context).textTheme.titleMedium),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _breathingCard(BuildContext context) {
    final AppL10n l = context.l10n;
    final String label = switch (_phase) {
      _Phase.breatheIn => l.t('calm.breatheIn'),
      _Phase.hold => l.t('calm.hold'),
      _Phase.breatheOut => l.t('calm.breatheOut'),
      _Phase.idle => l.t('calm.breathing'),
    };
    final double scale = switch (_phase) {
      _Phase.breatheIn => 1.0,
      _Phase.hold => 0.85,
      _Phase.breatheOut => 0.55,
      _Phase.idle => 0.7,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              height: 160,
              child: Center(
                child: AnimatedContainer(
                  duration: _movementOn
                      ? const Duration(milliseconds: 900)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  width: 150 * (_movementOn ? scale : 0.8),
                  height: 150 * (_movementOn ? scale : 0.8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal.withValues(alpha: 0.25),
                    border: Border.all(color: AppColors.teal, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _phase == _Phase.idle ? '' : '$_countdown',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: Icon(_phase == _Phase.idle
                  ? Icons.play_arrow
                  : Icons.stop),
              label: Text(_phase == _Phase.idle
                  ? l.t('timer.start')
                  : l.t('common.stop')),
              onPressed: () =>
                  _phase == _Phase.idle ? _startBreathing() : _stopBreathing(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coloringCard(BuildContext context) {
    final AppL10n l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l.t('calm.coloring'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ..._palette.map(
                  (Color c) => GestureDetector(
                    onTap: () => setState(() => _brush = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _brush == c
                            ? Border.all(width: 3, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.t('creative.clear'),
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => setState(_colorStrokes.clear),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: GestureDetector(
                onPanUpdate: (DragUpdateDetails d) =>
                    setState(() => _colorStrokes.add(d.localPosition)),
                onPanEnd: (DragEndDetails d) =>
                    setState(() => _colorStrokes.add(null)),
                child: CustomPaint(
                  painter: _CalmPainter(strokes: _colorStrokes, color: _brush),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outline),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalmSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setSheet) =>
            SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SwitchListTile(
                title: Text(context.l10n.t('calm.disableSound')),
                value: _soundOn,
                onChanged: (bool v) => setSheet(() => _soundOn = v),
              ),
              SwitchListTile(
                title: Text(context.l10n.t('calm.disableAnim')),
                value: _movementOn,
                onChanged: (bool v) => setSheet(() => _movementOn = v),
              ),
              SwitchListTile(
                title: Text(context.l10n.t('calm.disableVibe')),
                value: _vibrationOn,
                onChanged: (bool v) => setSheet(() => _vibrationOn = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalmPainter extends CustomPainter {
  _CalmPainter({required this.strokes, required this.color});

  final List<Offset?> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < strokes.length; i++) {
      final Offset? p = strokes[i];
      if (p == null) continue;
      final Offset? prev = i > 0 ? strokes[i - 1] : null;
      if (prev != null) {
        canvas.drawLine(prev, p, paint);
      } else {
        canvas.drawCircle(p, 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CalmPainter oldDelegate) => true;
}

