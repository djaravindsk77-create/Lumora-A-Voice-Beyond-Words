import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../services/speech/tts_service.dart';

/// Visual Timer: large countdown ring with gentle colour shift, presets for
/// study/play/waiting/break/screen-time/meals/transitions, plus a custom
/// duration picker. Audio completion alert + optional haptics.
class VisualTimerScreen extends StatefulWidget {
  const VisualTimerScreen({super.key});

  @override
  State<VisualTimerScreen> createState() => _VisualTimerScreenState();
}

class _VisualTimerScreenState extends State<VisualTimerScreen> {
  static const List<int> _presets = <int>[1, 3, 5, 10, 15, 20, 30];

  Timer? _ticker;
  int _totalSeconds = 5 * 60;
  int _remaining = 5 * 60;
  bool _running = false;
  bool _finished = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    FeedbackService.tap();
    setState(() {
      _running = true;
      _finished = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        }
        if (_remaining == 0) {
          _running = false;
          _finished = true;
          t.cancel();
          FeedbackService.confirm();
          TtsService.instance.speak('Time is up! Great waiting!');
        }
      });
    });
  }

  void _pause() {
    _ticker?.cancel();
    FeedbackService.tap();
    setState(() => _running = false);
  }

  void _reset() {
    _ticker?.cancel();
    FeedbackService.tap();
    setState(() {
      _running = false;
      _finished = false;
      _remaining = _totalSeconds;
    });
  }

  void _setMinutes(int minutes) {
    _ticker?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remaining = _totalSeconds;
      _running = false;
      _finished = false;
    });
  }

  String _fmt(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final double progress =
        _totalSeconds == 0 ? 0 : _remaining / _totalSeconds;
    final Color ringColor = _finished
        ? AppColors.success
        : progress > 0.5
            ? AppColors.teal
            : progress > 0.2
                ? AppColors.yellow
                : AppColors.orange;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('timer.title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    color: ringColor,
                  ),
                  child: Center(
                    child: Text(
                      _finished ? '✓' : _fmt(_remaining),
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: ringColor),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running
                      ? l.t('timer.pause')
                      : (_remaining == _totalSeconds
                          ? l.t('timer.start')
                          : l.t('timer.resume'))),
                  onPressed: _finished
                      ? null
                      : () => _running ? _pause() : _start(),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: Text(l.t('timer.reset')),
                  onPressed: _reset,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l.t('timer.custom'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map((int m) => OutlinedButton(
                        onPressed: () => _setMinutes(m),
                        child: Text(l.t('timer.minutes',
                            <String, String>{'count': '$m'})),
                      ))
                  .toList(),
            ),
            if (_finished)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  l.t('timer.done'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bg = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    final Paint fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final Rect rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(10), 0, 3.14159 * 2, false, bg);
    canvas.drawArc(
        rect.deflate(10), -3.14159 / 2, 3.14159 * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
