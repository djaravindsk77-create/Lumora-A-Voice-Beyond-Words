import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/emotion_entry.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

enum _MoodView { history, calendar }

/// Parent-facing mood history + simple mood calendar. Shows exactly what
/// the child selected; entries are never interpreted or scored.
class EmotionHistoryScreen extends StatefulWidget {
  const EmotionHistoryScreen({super.key});

  @override
  State<EmotionHistoryScreen> createState() => _EmotionHistoryScreenState();
}

class _EmotionHistoryScreenState extends State<EmotionHistoryScreen> {
  _MoodView _view = _MoodView.history;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final String childId = session.child?.id ?? '';
    final List<EmotionEntry> entries = LumoraRepository.instance
        .getEmotionEntries()
        .where((EmotionEntry e) => e.childId == childId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('feel.history')),
        actions: <Widget>[
          SignOutButton(),
          SegmentedButton<_MoodView>(
            segments: const <ButtonSegment<_MoodView>>[
              ButtonSegment<_MoodView>(
                  value: _MoodView.history, icon: Icon(Icons.list)),
              ButtonSegment<_MoodView>(
                  value: _MoodView.calendar, icon: Icon(Icons.calendar_month)),
            ],
            selected: <_MoodView>{_view},
            onSelectionChanged: (Set<_MoodView> s) =>
                setState(() => _view = s.first),
          ),
        ],
      ),
      body: entries.isEmpty
          ? EmptyView(
              title: l.t('feel.noData'),
              icon: Icons.sentiment_neutral,
            )
          : _view == _MoodView.history
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (BuildContext context, int i) {
                    final EmotionEntry e = entries[i];
                    final Color color =
                        AppColors.fromName(EmotionCatalog.colorName(e.emotionId));
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(
                            IconCatalog.of(
                                EmotionCatalog.iconKey(e.emotionId)),
                            color: color,
                          ),
                        ),
                        title: Text(l.t('emo.${e.emotionId}')),
                        subtitle: Text(
                          '${e.comfortChoiceId != null ? 'Comfort: ${e.comfortChoiceId} · ' : ''}'
                          '${e.notifiedCaregiver ? 'Caregivers notified' : 'Not notified'}',
                        ),
                        trailing: Text(
                          '${e.createdAt?.day}/${e.createdAt?.month}',
                        ),
                      ),
                    );
                  },
                )
              : _buildCalendar(context, entries),
    );
  }

  Widget _buildCalendar(BuildContext context, List<EmotionEntry> entries) {
    final DateTime now = DateTime.now();
    final Map<int, String> dayMood = <int, String>{};
    for (final EmotionEntry e in entries) {
      final DateTime? d = e.createdAt;
      if (d != null &&
          d.year == now.year &&
          d.month == now.month) {
        dayMood[d.day] = e.emotionId;
      }
    }
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${now.month}/${now.year}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: daysInMonth,
              itemBuilder: (BuildContext context, int i) {
                final int day = i + 1;
                final String? mood = dayMood[day];
                final Color color = mood == null
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : AppColors.fromName(EmotionCatalog.colorName(mood));
                return Tooltip(
                  message: mood == null
                      ? ''
                      : EmotionCatalog.colorName(mood),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: mood == null ? 1 : 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$day',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
