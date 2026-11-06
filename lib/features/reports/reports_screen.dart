import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utilities/formatters.dart';
import '../../features/learning/learning_catalog.dart';
import '../../models/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/learning_provider.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

enum _ReportPeriod { daily, weekly, monthly }

/// Reports & Analytics: communication frequency, method usage, emotions,
/// learning, routines, alerts and caregiver observations - with daily /
/// weekly / monthly filters, export and delete-history. All content is
/// descriptive activity data only (never diagnostic).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportPeriod _period = _ReportPeriod.weekly;

  int get _days {
    switch (_period) {
      case _ReportPeriod.daily:
        return 1;
      case _ReportPeriod.weekly:
        return 7;
      case _ReportPeriod.monthly:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final CommunicationProvider comm = context.watch<CommunicationProvider>();
    final String childId =
        context.watch<SessionProvider>().child?.id ?? '';
    final LumoraRepository repo = LumoraRepository.instance;

    final List<CommunicationActivity> acts = comm.activities
        .where((CommunicationActivity a) =>
            a.childId == childId &&
            a.createdAt != null &&
            DateTime.now().difference(a.createdAt!).inDays < _days)
        .toList();

    final Map<CommMethod, int> byMethod = <CommMethod, int>{};
    for (final CommunicationActivity a in acts) {
      byMethod[a.method] = (byMethod[a.method] ?? 0) + 1;
    }

    final List<EmotionEntry> emotions = repo
        .getEmotionEntries()
        .where((EmotionEntry e) =>
            e.childId == childId &&
            e.createdAt != null &&
            DateTime.now().difference(e.createdAt!).inDays < _days)
        .toList();

    final List<RoutineCompletion> completions = repo
        .getRoutineCompletions()
        .where((RoutineCompletion c) =>
            c.childId == childId &&
            DateTime.now().difference(c.completedAt).inDays < _days)
        .toList();

    final List<SafetyAlert> alerts = repo
        .getAlerts()
        .where((SafetyAlert a) =>
            DateTime.now().difference(a.createdAt).inDays < _days)
        .toList();

    final List<CaregiverNote> notes =
        repo.getNotes().where((CaregiverNote n) => n.childId == childId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('report.title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            SegmentedButton<_ReportPeriod>(
              segments: <ButtonSegment<_ReportPeriod>>[
                ButtonSegment<_ReportPeriod>(
                    value: _ReportPeriod.daily,
                    label: Text(l.t('report.daily'))),
                ButtonSegment<_ReportPeriod>(
                    value: _ReportPeriod.weekly,
                    label: Text(l.t('report.weekly'))),
                ButtonSegment<_ReportPeriod>(
                    value: _ReportPeriod.monthly,
                    label: Text(l.t('report.monthly'))),
              ],
              selected: <_ReportPeriod>{_period},
              onSelectionChanged: (Set<_ReportPeriod> s) =>
                  setState(() => _period = s.first),
            ),
            const SizedBox(height: 12),
            _chartCard(
              context,
              title: l.t('report.methods'),
              child: MethodPieChart(
                sections: <(String, int, String)>[
                  (l.t('track.aacUsage'), byMethod[CommMethod.aac] ?? 0, 'purple'),
                  (l.t('track.voiceUsage'), byMethod[CommMethod.voice] ?? 0, 'blue'),
                  (l.t('track.sentenceUsage'),
                      byMethod[CommMethod.sentenceBuilder] ?? 0, 'teal'),
                  (l.t('needs.title'), byMethod[CommMethod.needs] ?? 0, 'orange'),
                  (l.t('feel.title'), byMethod[CommMethod.emotions] ?? 0, 'yellow'),
                ],
              ),
            ),
            _chartCard(
              context,
              title: l.t('report.emotions'),
              child: emotions.isEmpty
                  ? _noData(context)
                  : Column(
                      children: emotions
                          .take(6)
                          .map(
                            (EmotionEntry e) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.mood),
                              title: Text(l.t('emo.${e.emotionId}')),
                              trailing: Text(AppFormatters.date(
                                  context, e.createdAt!)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            _chartCard(
              context,
              title: l.t('report.learning'),
              child: Builder(
                builder: (BuildContext context) {
                  final LearningProvider learning =
                      context.watch<LearningProvider>();
                  if (learning.progress.isEmpty) {
                    return _noData(context);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${l.t('learn.stars')}: ${learning.totalStars(childId)} · '
                        '${l.t('learn.accuracy')}: '
                        '${(learning.averageAccuracy(childId) * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      ...learning.progress.take(5).map(
                            (LearningProgress p) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.extension),
                              title: Text(
                                  _activityTitle(l, p.activityId)),
                              subtitle: Text(
                                '${p.correctCount}/${p.totalCount} · '
                                '${l.t('learn.stars')}: ${p.starsEarned}/3',
                              ),
                              trailing: Text(
                                  AppFormatters.date(context, p.completedAt)),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
            _chartCard(
              context,
              title: l.t('report.routines'),
              child: completions.isEmpty
                  ? _noData(context)
                  : Column(
                      children: completions
                          .take(6)
                          .map(
                            (RoutineCompletion c) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.checklist),
                              title: Text(
                                  '${c.completedTasks}/${c.totalTasks}'),
                              trailing: Text(AppFormatters.date(
                                  context, c.completedAt)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            _chartCard(
              context,
              title: l.t('report.safety'),
              child: alerts.isEmpty
                  ? Text(l.t('safety.noAlerts'),
                      style: Theme.of(context).textTheme.bodySmall)
                  : Column(
                      children: alerts
                          .take(5)
                          .map(
                            (SafetyAlert a) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.shield),
                              title: Text(l.t(a.messageKey)),
                              trailing: Text(l.t('safety.${a.status}')),
                            ),
                          )
                          .toList(),
                    ),
            ),
            _chartCard(
              context,
              title: l.t('report.observations'),
              child: Column(
                children: <Widget>[
                  if (notes.isEmpty)
                    Text(l.t('parent.noNotes'),
                        style: Theme.of(context).textTheme.bodySmall)
                  else
                    ...notes.take(4).map(
                          (CaregiverNote n) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.sticky_note_2),
                            title: Text(n.text, maxLines: 2),
                            subtitle: Text(n.authorName),
                          ),
                        ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        // Export: share a plain-text summary.
                        final StringBuffer buf = StringBuffer();
                        buf.writeln('Lumora report - $_period');
                        buf.writeln('Communication events: ${acts.length}');
                        buf.writeln('Emotions recorded: ${emotions.length}');
                        buf.writeln(
                            'Routine completions: ${completions.length}');
                        buf.writeln('Safety alerts: ${alerts.length}');
                        await ShareBridge.share(buf.toString());
                      },
                      child: Text(l.t('common.export')),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l.t('report.noteOnly'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(BuildContext context,
      {required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _noData(BuildContext context) => Text(
        context.l10n.t('report.noData'),
        style: Theme.of(context).textTheme.bodySmall,
      );

  static String _activityTitle(AppL10n l, String activityId) {
    final LearningActivity? a = LearningCatalog.byId(activityId);
    return a == null ? activityId : l.t(a.titleKey);
  }
}

/// Indirection for share_plus so tests do not need the plugin.
class ShareBridge {
  static Future<void> Function(String text)? _impl;

  static void bind(Future<void> Function(String) impl) => _impl = impl;

  static Future<void> share(String text) async {
    if (_impl != null) return _impl!(text);
    // Default no-op in demo/tests.
  }
}
