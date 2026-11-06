import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/barrel.dart';
import '../../providers/learning_provider.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// Therapist Dashboard: view assigned children, add therapy notes and goals,
/// monitor learning progress, and view child profiles and progress reports.
///
/// Reuses existing repository + models. Notes and goals are stored locally
/// via the existing CaregiverNote and LumoraRepository APIs.
class TherapistDashboardScreen extends StatefulWidget {
  const TherapistDashboardScreen({super.key});

  @override
  State<TherapistDashboardScreen> createState() =>
      _TherapistDashboardScreenState();
}

enum _TPeriod { daily, weekly, monthly }

class _TherapistDashboardScreenState
    extends State<TherapistDashboardScreen> {
  _TPeriod _period = _TPeriod.weekly;
  bool get _hasPrimaryChild =>
      (context.read<SessionProvider>().child?.id ?? '').isNotEmpty;

  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SessionProvider session = context.read<SessionProvider>();
      final LearningProvider learning = context.read<LearningProvider>();
      if (session.role != UserRole.therapist) return;
      await learning.load(session.child?.id ?? '');
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  int _days(_TPeriod p) {
    switch (p) {
      case _TPeriod.daily:
        return 1;
      case _TPeriod.weekly:
        return 7;
      case _TPeriod.monthly:
        return 30;
    }
  }

  List<ChildProfile> _assignedChildren() {
    final SessionProvider session = context.read<SessionProvider>();
    final LumoraRepository repo = LumoraRepository.instance;
    // Therapists see children shared with them via permissions, plus the
    // active child if one is set.
    final List<ChildProfile> shared =
        repo.getPermissions().where((CaregiverPermission p) {
      return p.isActive &&
          p.role == UserRole.therapist &&
          p.invitedUserId == (session.user?.id ?? '');
    }).map((CaregiverPermission p) => repo.getChild(p.childId))
        .whereType<ChildProfile>()
        .toList();
    if (shared.isNotEmpty) return shared;
    final ChildProfile? active = session.child;
    if (active != null) return <ChildProfile>[active];
    return repo.getChildren();
  }

  List<CaregiverNote> _therapyNotes(String childId) {
    final LumoraRepository repo = LumoraRepository.instance;
    final int days = _days(_period);
    return repo.getNotes()
        .where((CaregiverNote n) =>
            n.childId == childId &&
            n.noteType == 'therapist' &&
            n.createdAt != null &&
            DateTime.now().difference(n.createdAt!).inDays < days)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final LearningProvider learning =
        context.watch<LearningProvider>();
    final LumoraRepository repo = LumoraRepository.instance;

    final List<ChildProfile> children = _assignedChildren();
    if (_hasPrimaryChild) {
      final ChildProfile? active =
          children.where((ChildProfile c) =>
              c.id == context.read<SessionProvider>().child?.id)
              .firstOrNull;
      if (active != null) {
        // The existing primary child selection continues unaffected.
      }
    }
    final ChildProfile activeChild =
        children.isNotEmpty ? children.first : const ChildProfile(
            id: 'unknown',
            name: l.t('parent.selectChild'),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('therapist.dashboard')),
        actions: <Widget>[
          IconButton(
            tooltip: l.t('profile.title'),
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            tooltip: l.t('settings.title'),
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          const SignOutButton(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_2),
            onSelected: (String value) {
              if (value == 'switchChild')
                context.push('/parent/child');
              else if (value == 'switchRole')
                context.push('/profile');
              else if (value == 'viewAll')
                context.push('/admin/dashboard');
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'switchChild',
                child: Row(
                  children: [
                    const Icon(Icons.child_care, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.t('therapist.switchChild')),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'switchRole',
                child: Row(
                  children: [
                    const Icon(Icons.badge, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.t('therapist.switchRole')),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'viewAll',
                child: Row(
                  children: [
                    const Icon(Icons.dashboard, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.t('therapist.switchToAdmin')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            // ---- Therapist stats {card} ----
            Card(
              color: AppColors.purple.withValues(alpha: 0.10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.purple,
                      child:
                          Icon(Icons.healing, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.t('therapist.welcome'),
                            style:
                                Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            session.user?.email ?? '-',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(l.t('role.therapist')),
                      backgroundColor:
                          AppColors.purple.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Child selector ----
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Text(
                      l.t('therapist.assignedChildren'),
                      style:
                          Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: children.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (BuildContext ctx, int i) {
                      final ChildProfile child = children[i];
                      final bool isActive =
                          session.child?.id == child.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? AppColors.purple
                                  .withValues(alpha: 0.15)
                              : AppColors.outline
                                  .withValues(alpha: 0.2),
                          child: Text(child.name.isNotEmpty
                              ? child.name[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(
                          child.name +
                              (isActive
                                  ? ''
                                  : '  ·  ${l.t("parent.viewAll")}'),
                          style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                        subtitle: Text(
                            '${l.t('parent.age')}: ${child.age} · ${child.learningLevel}'),
                        trailing: isActive
                            ? const Icon(Icons.check_circle,
                                color: AppColors.purple, size: 22)
                            : null,
                        selected: isActive,
                        selectedTileColor:
                            AppColors.purple.withValues(alpha: 0.06),
                        onTap: () {
                          session.setChild(child);
                          final LearningProvider lp =
                              context.read<LearningProvider>();
                          lp.load(child.id);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Stats ----
            final double accuracy =
                learning.averageAccuracy(activeChild.id) * 100;
            final int totalStars = learning.totalStars(activeChild.id);
            final int sessions = learning.progress.length;
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: <Widget>[
                StatTile(
                  label: l.t('learn.accuracy'),
                  value: '${(accuracy).round()}%',
                  icon: Icons.track_changes,
                  colorName: 'green',
                ),
                StatTile(
                  label: l.t('learn.stars'),
                  value: '$totalStars',
                  icon: Icons.star,
                  colorName: 'yellow',
                ),
                StatTile(
                  label: l.t('learn.sessions'),
                  value: '$sessions',
                  icon: Icons.school,
                  colorName: 'teal',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Therapy notes ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.sticky_note_2,
                            color: AppColors.purple),
                        const SizedBox(width: 8),
                        Text(
                          l.t('therapist.therapyNotes'),
                          style:
                              Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.purple,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _noteCtrl,
                            decoration: InputDecoration(
                              hintText: l.t('therapist.noteHint'),
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () =>
                              _addNote(context, activeChild.id),
                          icon: const Icon(Icons.add),
                          label: Text(l.t('therapist.addNote')),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                        l.t('therapist.notesFor') +
                            ': ${activeChild.name}',
                        style:
                            Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    if (_therapyNotes(activeChild.id).isEmpty)
                      Text(
                        l.t('therapist.noNotes'),
                        style:
                            Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      ..._therapyNotes(activeChild.id).map(
                            (CaregiverNote n) => ListTile(
                              dense: true,
                              leading: const Icon(
                                  Icons.sticky_note_2,
                                  size: 18,
                                  color: AppColors.purple),
                              title: Text(n.text, maxLines: 2),
                              subtitle: Text(
                                  '${n.createdAt?.toString().split(' ')[0] ?? ""} · ${l.t('therapist.byTherapist')}'),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Therapy goals ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.flag,
                            color: AppColors.orange),
                        const SizedBox(width: 8),
                        Text(
                          l.t('therapist.goals'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.orange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _goalCtrl,
                            decoration: InputDecoration(
                              hintText: l.t('therapist.goalHint'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () =>
                              _addGoal(context, activeChild.id),
                          icon: const Icon(Icons.add),
                          label: Text(l.t('therapist.addGoal')),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Goals are stored as CaregiverNotes with
                    // noteType 'goal'.
                    if (_therapyNotes(activeChild.id)
                            .where((CaregiverNote n) =>
                                n.noteType == 'goal')
                            .isEmpty)
                      Text(
                        l.t('therapist.noGoals'),
                        style:
                            Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      ..._therapyNotes(activeChild.id)
                          .where((CaregiverNote n) =>
                              n.noteType == 'goal')
                          .take(5)
                          .map(
                            (CaregiverNote n) => ListTile(
                              dense: true,
                              leading: const Icon(
                                  Icons.flag,
                                  size: 18,
                                  color: AppColors.orange),
                              title: Text(n.text, maxLines: 1),
                              subtitle: Text(
                                  '${n.createdAt?.toString().split(' ')[0] ?? ""}'),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: AppColors.success),
                                onPressed: () =>
                                    _markGoalDone(context, n.id),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Progress reports ----
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.bar_chart,
                        color: AppColors.green),
                    title: Text(l.t('therapist.progressReports')),
                    subtitle: Text(
                        l.t('therapist.reportsFor') +
                            ': ${activeChild.name}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/learn/progress'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                        Icons.sentiment_satisfied,
                        color: AppColors.yellow),
                    title: Text(l.t('therapist.emotionHistory')),
                    subtitle: Text(
                        l.t('therapist.emotionsFor') +
                            ': ${activeChild.name}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/emotions/history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.checklist,
                        color: AppColors.teal),
                    title: Text(l.t('therapist.routineProgress')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/routines'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.accessibility,
                        color: AppColors.blue),
                    title: Text(l.t('therapist.aacUsage')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/voice'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/parent/child'),
              icon: const Icon(Icons.face_retouching_natural),
              label: Text(l.t('therapist.viewProfile')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote(BuildContext context, String childId) async {
    final AppL10n l = context.l10n;
    final String text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    final LumoraRepository repo = LumoraRepository.instance;
    final CaregiverNote note = CaregiverNote(
      id: 'note-${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      authorName:
          context.read<SessionProvider>().user?.name ?? 'Therapist',
      authorRole: 'therapist',
      noteType: 'therapist',
      text: text,
      createdAt: DateTime.now(),
    );
    await repo.saveNote(note);
    _noteCtrl.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('therapist.noteAdded'))),
      );
    }
  }

  Future<void> _addGoal(BuildContext context, String childId) async {
    final AppL10n l = context.l10n;
    final String text = _goalCtrl.text.trim();
    if (text.isEmpty) return;
    final LumoraRepository repo = LumoraRepository.instance;
    final CaregiverNote goal = CaregiverNote(
      id: 'goal-${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      authorName:
          context.read<SessionProvider>().user?.name ?? 'Therapist',
      authorRole: 'therapist',
      noteType: 'goal',
      text: text,
      createdAt: DateTime.now(),
    );
    await repo.saveNote(goal);
    _goalCtrl.clear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('therapist.goalAdded'))),
      );
    }
  }

  Future<void> _markGoalDone(BuildContext context, String noteId) async {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final List<CaregiverNote> notes = repo.getNotes();
    final CaregiverNote? note =
        notes.where((CaregiverNote n) => n.id == noteId).firstOrNull;
    if (note == null) return;
    await repo.saveNote(note.copyWith(
      text: '✓ ${note.text}',
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('therapist.goalMarked'))),
      );
    }
  }
}
