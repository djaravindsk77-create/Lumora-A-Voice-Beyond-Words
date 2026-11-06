import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// Communication Confidence Tracker.
/// Compares the child only with their own past activity, uses encouraging
/// language, offers badges, caregiver notes and full parent controls
/// (disable tracking, delete history).
class ConfidenceTrackerScreen extends StatefulWidget {
  const ConfidenceTrackerScreen({super.key});

  @override
  State<ConfidenceTrackerScreen> createState() =>
      _ConfidenceTrackerScreenState();
}

class _ConfidenceTrackerScreenState extends State<ConfidenceTrackerScreen> {
  bool _weekly = true;

  List<int> _dailyCounts(List<CommunicationActivity> acts, int days) {
    final DateTime now = DateTime.now();
    return List<int>.generate(days, (int i) {
      final DateTime day =
          DateTime(now.year, now.month, now.day - (days - 1 - i));
      return acts
          .where((CommunicationActivity a) =>
              a.createdAt != null &&
              DateTime(a.createdAt!.year, a.createdAt!.month, a.createdAt!.day) ==
                  day)
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final CommunicationProvider comm = context.watch<CommunicationProvider>();
    final SessionProvider session = context.watch<SessionProvider>();
    final String childId = session.child?.id ?? '';
    final List<CommunicationActivity> acts = comm.activities
        .where((CommunicationActivity a) => a.childId == childId)
        .toList();

    final Map<CommMethod, int> byMethod = <CommMethod, int>{};
    for (final CommunicationActivity a in acts) {
      byMethod[a.method] = (byMethod[a.method] ?? 0) + 1;
    }

    final Map<String, int> wordFreq = <String, int>{};
    for (final CommunicationActivity a in acts) {
      wordFreq[a.content] = (wordFreq[a.content] ?? 0) + 1;
    }
    final List<String> topContent = (wordFreq.entries.toList()
          ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value)))
        .take(5)
        .map((MapEntry<String, int> e) => e.key)
        .toList();

    final int independent =
        acts.where((CommunicationActivity a) => !a.assisted).length;
    final int assisted = acts.length - independent;
    final int today = _dailyCounts(acts, 1).first;
    final int week = _dailyCounts(acts, 7).fold(0, (int a, int b) => a + b);

    final bool trackingOn =
        context.watch<SettingsProvider>().settings.trackingEnabled;
    final List<CaregiverNote> notes = LumoraRepository.instance
        .getNotes()
        .where((CaregiverNote n) => n.childId == childId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('track.title')),
        actions: const <Widget>[SignOutButton()],
      ),
      body: acts.isEmpty && !trackingOn
          ? EmptyView(
              title: l.t('track.trackingOff'),
              icon: Icons.track_changes,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  trackingOn
                      ? l.t('track.greatJob')
                      : l.t('track.trackingOff'),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l.t('track.compareNote'),
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: StatTile(
                        label: l.t('track.daily'),
                        value: '$today',
                        icon: Icons.today,
                        colorName: 'blue',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: l.t('track.weekly'),
                        value: '$week',
                        icon: Icons.date_range,
                        colorName: 'teal',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(l.t('report.frequency'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                            ),
                            SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment<bool>(
                                    value: false, label: Text('7d')),
                                ButtonSegment<bool>(
                                    value: true, label: Text('14d')),
                              ],
                              selected: <bool>{_weekly},
                              onSelectionChanged: (Set<bool> s) =>
                                  setState(() => _weekly = s.first),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        WeeklyBarChart(
                          values: _dailyCounts(acts, _weekly ? 14 : 7),
                          labels: List<String>.generate(
                            _weekly ? 14 : 7,
                            (int i) => '${i + 1}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.t('report.methods'),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        MethodPieChart(
                          sections: <(String, int, String)>[
                            (l.t('track.aacUsage'), byMethod[CommMethod.aac] ?? 0, 'purple'),
                            (l.t('track.voiceUsage'), byMethod[CommMethod.voice] ?? 0, 'blue'),
                            (l.t('track.sentenceUsage'),
                                byMethod[CommMethod.sentenceBuilder] ?? 0, 'teal'),
                            (l.t('needs.title'), byMethod[CommMethod.needs] ?? 0, 'orange'),
                            (l.t('feel.title'), byMethod[CommMethod.emotions] ?? 0, 'yellow'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(l.t('track.frequentPhrases'),
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (topContent.isEmpty)
                          Text(l.t('report.noData'),
                              style: Theme.of(context).textTheme.bodySmall)
                        else
                          ...topContent.map(
                            (String s) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.chat_bubble),
                              title: Text(s),
                            ),
                          ),
                        const Divider(),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: StatTile(
                                label: l.t('track.independent'),
                                value: '$independent',
                                icon: Icons.person,
                                colorName: 'green',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                label: l.t('track.assisted'),
                                value: '$assisted',
                                icon: Icons.handshake,
                                colorName: 'yellow',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.t('track.badges'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _badge(context, l.t('track.badgeFirstWords'),
                        acts.isNotEmpty, Icons.emoji_events),
                    _badge(context, l.t('track.badgeTalker'),
                        acts.length >= 25, Icons.record_voice_over),
                    _badge(context, l.t('track.badgeBuilder'),
                        byMethod.containsKey(CommMethod.sentenceBuilder),
                        Icons.format_align_left),
                    _badge(context, l.t('track.badgeFeelings'),
                        byMethod.containsKey(CommMethod.emotions),
                        Icons.sentiment_satisfied),
                    _badge(context, l.t('track.badgeRoutine'), week >= 20,
                        Icons.checklist),
                    _badge(context, l.t('track.badgeCalm'), acts.length >= 60,
                        Icons.spa),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l.t('track.notes'),
                    style: Theme.of(context).textTheme.titleMedium),
                if (notes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l.t('track.noNotes'),
                        style: Theme.of(context).textTheme.bodySmall),
                  )
                else
                  ...notes.take(3).map(
                        (CaregiverNote n) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.sticky_note_2),
                            title: Text(n.text),
                            subtitle: Text(n.authorName),
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.pause_circle),
                        label: Text(l.t('track.disableTracking')),
                        onPressed: () => context
                            .read<SettingsProvider>()
                            .setTrackingEnabled(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: Text(l.t('track.deleteHistory')),
                        onPressed: () async {
                          final bool? ok = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext ctx) => AlertDialog(
                              title: Text(l.t('common.deleteTitle')),
                              content: Text(l.t('common.confirmDelete')),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l.t('common.cancel')),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l.t('common.delete')),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await LumoraRepository.instance.clearHistory();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(l.t('track.historyDeleted'))),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (!trackingOn)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton(
                      onPressed: () => context
                          .read<SettingsProvider>()
                          .setTrackingEnabled(true),
                      child: Text(l.t('common.enabled')),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _badge(BuildContext context, String label, bool earned, IconData icon) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: earned
            ? cs.primary.withValues(alpha: 0.15)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: earned ? cs.primary : cs.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon,
              size: 20,
              color: earned ? cs.primary : cs.outline),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
