import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utilities/formatters.dart';
import '../../features/learning/learning_catalog.dart';
import '../../models/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/learning_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/safety_provider.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// Parent/Caregiver Dashboard: activity overview, most-used phrases,
/// emotion history, learning progress, routine completion, safety alerts,
/// caregiver notes and recommendations - with filters by period.
class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

enum _Period { daily, weekly, monthly }

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  _Period _period = _Period.weekly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Hoist all provider reads before the first await so no BuildContext
      // is used across an async gap.
      final SessionProvider session = context.read<SessionProvider>();
      final RoutineProvider routines = context.read<RoutineProvider>();
      final SafetyProvider safety = context.read<SafetyProvider>();
      final CommunicationProvider comm = context.read<CommunicationProvider>();
      final LearningProvider learning = context.read<LearningProvider>();
      final String childId = session.child?.id ?? '';
      if (childId.isEmpty) return;
      await routines.load(childId);
      await safety.load(childId);
      await comm.load(childId);
      await learning.load(childId);
    });
  }

  int _days(_Period p) {
    switch (p) {
      case _Period.daily:
        return 1;
      case _Period.weekly:
        return 7;
      case _Period.monthly:
        return 30;
    }
  }

  static String _activityTitle(AppL10n l, String activityId) {
    final LearningActivity? a = LearningCatalog.byId(activityId);
    return a == null ? activityId : l.t(a.titleKey);
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final CommunicationProvider comm = context.watch<CommunicationProvider>();
    final RoutineProvider routines = context.watch<RoutineProvider>();
    final SafetyProvider safety = context.watch<SafetyProvider>();
    final LearningProvider learning = context.watch<LearningProvider>();
    final LumoraRepository repo = LumoraRepository.instance;

    final String childId = session.child?.id ?? '';
    final List<CommunicationActivity> acts = comm.activities
        .where((CommunicationActivity a) =>
            a.childId == childId &&
            a.createdAt != null &&
            DateTime.now().difference(a.createdAt!).inDays <
                _days(_period))
        .toList();

    final Map<String, int> phraseFreq = <String, int>{};
    for (final CommunicationActivity a in acts) {
      phraseFreq[a.content] = (phraseFreq[a.content] ?? 0) + 1;
    }
    final List<MapEntry<String, int>> topPhrases =
        (phraseFreq.entries.toList()
              ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
                  b.value.compareTo(a.value)))
            .take(5)
            .toList();

    final Map<CommMethod, int> byMethod = <CommMethod, int>{};
    for (final CommunicationActivity a in acts) {
      byMethod[a.method] = (byMethod[a.method] ?? 0) + 1;
    }

    final List<EmotionEntry> emotions =
        repo.getEmotionEntries().where((EmotionEntry e) => e.childId == childId).toList();
    final List<CaregiverNote> notes =
        repo.getNotes().where((CaregiverNote n) => n.childId == childId).toList();
    final List<SafetyAlert> alerts = safety.alerts;
    final double routineRatio = routines.completionRatio;

    return Scaffold(
      appBar: AppBar(
        // Every adult role (parent, caregiver, teacher, therapist, admin)
        // lands on this dashboard, so the way out of the account lives here.
        title: Text(l.t('parent.dashboard')),
        actions: <Widget>[
          IconButton(
            tooltip: l.t('profile.title'),
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: l.t('notif.title'),
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: l.t('settings.title'),
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          const SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            // Child profile header.
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                    child: Icon(Icons.face)),
                title: Text(session.child?.name ?? '-',
                    style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text(
                    '${l.t('parent.age')}: ${session.child?.age ?? '-'} · '
                    '${session.child?.learningLevel ?? '-'}'),
                trailing: TextButton(
                  onPressed: () => context.push('/parent/child'),
                  child: Text(l.t('common.edit')),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_Period>(
              segments: <ButtonSegment<_Period>>[
                ButtonSegment<_Period>(
                    value: _Period.daily, label: Text(l.t('report.daily'))),
                ButtonSegment<_Period>(
                    value: _Period.weekly, label: Text(l.t('report.weekly'))),
                ButtonSegment<_Period>(
                    value: _Period.monthly, label: Text(l.t('report.monthly'))),
              ],
              selected: <_Period>{_period},
              onSelectionChanged: (Set<_Period> s) =>
                  setState(() => _period = s.first),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: <Widget>[
                StatTile(
                  label: l.t('parent.commActivity'),
                  value: '${acts.length}',
                  icon: Icons.forum,
                  colorName: 'blue',
                ),
                StatTile(
                  label: l.t('parent.emotionHistory'),
                  value: '${emotions.length}',
                  icon: Icons.sentiment_satisfied,
                  colorName: 'yellow',
                ),
                StatTile(
                  label: l.t('parent.routineCompletion'),
                  value: '${(routineRatio * 100).round()}%',
                  icon: Icons.checklist,
                  colorName: 'green',
                ),
                StatTile(
                  label: l.t('parent.safetyAlerts'),
                  value: '${alerts.length}',
                  icon: Icons.shield,
                  colorName: 'red',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.t('parent.commActivity'),
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
            Text(l.t('parent.mostUsed'),
                style: Theme.of(context).textTheme.titleMedium),
            if (topPhrases.isEmpty)
              Text(l.t('report.noData'),
                  style: Theme.of(context).textTheme.bodySmall)
            else
              ...topPhrases.map(
                (MapEntry<String, int> e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.chat_bubble),
                  title: Text(e.key),
                  trailing: Text('×${e.value}'),
                ),
              ),
            const SizedBox(height: 8),
            Text(l.t('parent.learning'),
                style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatTile(
                            label: l.t('learn.stars'),
                            value: '${learning.totalStars(childId)}',
                            icon: Icons.star,
                            colorName: 'yellow',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatTile(
                            label: l.t('learn.sessions'),
                            value: '${learning.progress.length}',
                            icon: Icons.school,
                            colorName: 'teal',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatTile(
                            label: l.t('learn.accuracy'),
                            value: '${(learning.averageAccuracy(childId) * 100).round()}%',
                            icon: Icons.track_changes,
                            colorName: 'green',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l.t('learn.recent'),
                        style: Theme.of(context).textTheme.titleSmall),
                    if (learning.progress.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l.t('report.noData'),
                            style: Theme.of(context).textTheme.bodySmall),
                      )
                    else
                      ...learning.progress.take(3).map(
                            (LearningProgress p) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.extension),
                              title: Text(_activityTitle(l, p.activityId)),
                              subtitle: Text(
                                '${p.correctCount}/${p.totalCount} · '
                                '${l.t('learn.stars')}: ${p.starsEarned}/3',
                              ),
                              trailing: Text(AppFormatters.date(
                                  context, p.completedAt)),
                            ),
                          ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/learn/progress'),
                        child: Text(l.t('parent.viewAll')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(l.t('parent.notes'),
                style: Theme.of(context).textTheme.titleMedium),
            if (notes.isEmpty)
              Text(l.t('parent.noNotes'),
                  style: Theme.of(context).textTheme.bodySmall)
            else
              ...notes.take(3).map(
                    (CaregiverNote n) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.sticky_note_2),
                        title: Text(n.text, maxLines: 2),
                        subtitle: Text('${n.authorName} · ${n.authorRole}'),
                      ),
                    ),
                  ),
            const SizedBox(height: 8),
            Text(l.t('parent.recommendations'),
                style: Theme.of(context).textTheme.titleMedium),
            ...learning.recommendations(childId).map(
                  (a) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.recommend),
                    title: Text(l.t(a.titleKey)),
                  ),
                ),
            const SizedBox(height: 12),
            // Quick management links.
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.grid_view),
                    title: Text(l.t('parent.content')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/parent/content'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.connect_without_contact),
                    title: Text(l.t('parent.collaboration')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/collaboration'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: Text(l.t('parent.reports')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/reports'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.contacts),
                    title: Text(l.t('safety.contacts')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/trusted-contacts'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(l.t('parent.homeLayout')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/parent/home-layout'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.face_retouching_natural),
                    title: Text(l.t('parent.children')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/parent/child'),
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
