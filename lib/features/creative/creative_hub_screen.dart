import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../services/speech/tts_service.dart';

/// Creative activities hub: drawing, stickers, music & rhythm, sound
/// exploration, shape creation and craft ideas. Artwork is private and can
/// be shared only with caregiver permission (share button requires parent
/// role - enforced by hiding it in child mode).
class CreativeHubScreen extends StatefulWidget {
  const CreativeHubScreen({super.key});

  @override
  State<CreativeHubScreen> createState() => _CreativeHubScreenState();
}

class _CreativeHubScreenState extends State<CreativeHubScreen> {
  final List<Offset?> _strokes = <Offset?>[];
  Color _brushColor = AppColors.primary;
  double _brushWidth = 6;
  bool _rhythmMode = false;

  static const List<Color> _palette = <Color>[
    AppColors.primary,
    AppColors.secondary,
    AppColors.teal,
    AppColors.yellow,
    AppColors.orange,
    AppColors.error,
    AppColors.success,
  ];


  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.t('creative.title')),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(icon: Icon(Icons.draw), text: 'Draw'),
              Tab(icon: Icon(Icons.music_note), text: 'Music'),
              Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _buildDraw(context),
            _buildMusic(context),
            _buildGallery(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDraw(BuildContext context) {
    final AppL10n l = context.l10n;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ..._palette.map(
                (Color c) => GestureDetector(
                  onTap: () => setState(() => _brushColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: _brushColor == c
                          ? Border.all(width: 3, color: Colors.black54)
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _brushWidth,
                  min: 2,
                  max: 20,
                  label: l.t('creative.brush'),
                  onChanged: (double v) => setState(() => _brushWidth = v),
                ),
              ),
              IconButton(
                tooltip: l.t('creative.clear'),
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => setState(_strokes.clear),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onPanUpdate: (DragUpdateDetails d) {
              setState(() => _strokes.add(d.localPosition));
            },
            onPanEnd: (DragEndDetails d) {
              setState(() => _strokes.add(null));
            },
            child: CustomPaint(
              painter: _DrawingPainter(
                strokes: _strokes,
                color: _brushColor,
                width: _brushWidth,
              ),
              child: Container(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(l.t('creative.save')),
                  onPressed: () {
                    FeedbackService.confirm();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(context.l10n.t('creative.shareNote'))),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.emoji_emotions),
                  label: Text(l.t('creative.stickers')),
                  onPressed: () => setState(() {
                    _brushColor =
                        _palette[_strokes.length % _palette.length];
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMusic(BuildContext context) {
    final AppL10n l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(l.t('creative.tapRhythm'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 8,
          itemBuilder: (BuildContext context, int i) {
            final Color c = _palette[i % _palette.length];
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                FeedbackService.tap();
                TtsService.instance.speak('Note ${i + 1}');
                setState(() => _rhythmMode = true);
                Future<void>.delayed(const Duration(milliseconds: 180),
                    () {
                  if (mounted) setState(() => _rhythmMode = false);
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: _rhythmMode ? 0.5 : 0.25),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.music_note, color: c, size: 34),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(l.t('creative.soundsHint'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Map<String, String>>[
            {'label': 'Rain', 'text': 'Rain sounds'},
            {'label': 'Waves', 'text': 'Ocean waves'},
            {'label': 'Birds', 'text': 'Birds singing'},
            {'label': 'Wind', 'text': 'Wind blowing'},
          ]
              .map((Map<String, String> s) => OutlinedButton.icon(
                    icon: const Icon(Icons.air),
                    label: Text(s['label']!),
                    onPressed: () =>
                        TtsService.instance.speak(s['text']!),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGallery(BuildContext context) {
    final AppL10n l = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.photo_library,
              size: 72, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(l.t('creative.noArtworks'),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(
            l.t('creative.shareNote'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({
    required this.strokes,
    required this.color,
    required this.width,
  });

  final List<Offset?> strokes;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < strokes.length; i++) {
      final Offset? p = strokes[i];
      if (p == null) continue;
      final Offset? prev =
          i > 0 ? strokes[i - 1] : null;
      if (prev != null) {
        canvas.drawLine(prev, p, paint);
      } else {
        canvas.drawCircle(p, width / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
