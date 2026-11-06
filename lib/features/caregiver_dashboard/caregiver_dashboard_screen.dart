import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/barrel.dart';
import '../../providers/communication_provider.dart';
import '../../providers/learning_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/safety_provider.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// Caregiver Dashboard: daily care hub for caregivers.
///
/// View and manage the active child's profile, access medical information,
/// view communication activities and learning progress, manage accessibility
/// settings, and trigger Emergency SOS with GPS location sharing.
///
/// Reuses the existing repository, providers and Safety SOS flow — the SOS
/// button routes to the existing SafetyScreen where EMERGENCY + location
/// sharing already works.
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

enum _CPeriod { daily, weekly, monthly }

class _CaregiverDashboardScreenState
    extends State<CaregiverDashboardScreen> {
  _CPeriod _period = _CPeriod.weekly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SessionProvider session = context.read<SessionProvider>();
      if (session.role != UserRole.caregiver) return;
      final RoutineProvider routines = context.read<RoutineProvider>();
      final SafetyProvider safety = context.read<SafetyProvider>();
      final CommunicationProvider comm =
          context.read<CommunicationProvider>();
      final LearningProvider learning = context.read<LearningProvider>();
      final String childId = session.child?.id ?? '';
      if (childId.isNotEmpty) {
        await routines.load(childId);
        await safety.load(childId);
        await comm.load(childId);
        await learning.load(childId);
      }
    });
  }

  int _days(_CPeriod p) {
    switch (p) {
      case _CPeriod.daily:
        return 1;
      case _CPeriod.weekly:
        return 7;
      case _CPeriod.monthly:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final CommunicationProvider comm =
        context.watch<CommunicationProvider>();
    final RoutineProvider routines = context.watch<RoutineProvider>();
    final SafetyProvider safety = context.watch<SafetyProvider>();
    final LearningProvider learning =
        context.watch<LearningProvider>();
    final LumoraRepository repo = LumoraRepository.instance;

    final ChildProfile? child = session.child;
    final String childId = child?.id ?? '';

    final List<CommunicationActivity> acts = comm.activities
        .where((CommunicationActivity a) =>
            a.childId == childId &&
            a.createdAt != null &&
            DateTime.now().difference(a.createdAt!).inDays <
                _days(_period))
        .toList();

    final double routineRatio = routines.completionRatio;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('caregiver.dashboard')),
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            // Caregiver header.
            Card(
              color: AppColors.orange.withValues(alpha: 0.10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.orange,
                      child: Icon(Icons.volunteer_activism,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.t('caregiver.welcome'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            session.user?.email ?? '-',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(l.t('role.caregiver')),
                      backgroundColor:
                          AppColors.orange.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Child profile card ----
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppColors.orange.withValues(alpha: 0.15),
                  child: const Icon(Icons.child_care),
                ),
                title: Text(
                  child?.name ?? l.t('caregiver.noChild'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  child != null
                      ? '${l.t('parent.age')}: ${child.age} · ${child.learningLevel}'
                      : '-',
                ),
                trailing: TextButton.icon(
                  onPressed: () => context.push('/parent/child'),
                  icon: const Icon(Icons.edit),
                  label: Text(l.t('common.edit')),
                ),
                onTap: () => context.push('/parent/child'),
              ),
            ),
            const SizedBox(height: 12),

            SegmentedButton<_CPeriod>(
              segments: <ButtonSegment<_CPeriod>>[
                ButtonSegment<_CPeriod>(
                    value: _CPeriod.daily,
                    label: Text(l.t('report.daily'))),
                ButtonSegment<_CPeriod>(
                    value: _CPeriod.weekly,
                    label: Text(l.t('report.weekly'))),
                ButtonSegment<_CPeriod>(
                    value: _CPeriod.monthly,
                    label: Text(l.t('report.monthly'))),
              ],
              selected: <_CPeriod>{_period},
              onSelectionChanged: (Set<_CPeriod> s) =>
                  setState(() => _period = s.first),
            ),
            const SizedBox(height: 12),

            // ---- Quick stats ----
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: <Widget>[
                StatTile(
                  label: l.t('caregiver.commActivity'),
                  value: '${acts.length}',
                  icon: Icons.forum,
                  colorName: 'blue',
                ),
                StatTile(
                  label: l.t('caregiver.routineCompletion'),
                  value: '${(routineRatio * 100).round()}%',
                  icon: Icons.checklist,
                  colorName: 'green',
                ),
                StatTile(
                  label: l.t('caregiver.safetyStatus'),
                  value: safety.sirenOn
                      ? l.t('caregiver.sirenActive')
                      : l.t('caregiver.safe'),
                  icon: safety.sirenOn
                      ? Icons.notifications_active
                      : Icons.check_circle,
                  colorName: safety.sirenOn ? 'red' : 'green',
                ),
                StatTile(
                  label: l.t('caregiver.stars'),
                  value: '${learning.totalStars(childId)}',
                  icon: Icons.star,
                  colorName: 'yellow',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Emergency SOS ----
            Card(
              color: AppColors.error.withValues(alpha: 0.06),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.emergency,
                          color: AppColors.error, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l.t('caregiver.emergencySOS'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: AppColors.error),
                            ),
                            Text(
                              l.t('caregiver.sosSubtitle'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            context.push('/safety'),
                        icon: const Icon(Icons.share_location,
                            color: Colors.white),
                        label: Text(l.t('caregiver.sosButton')),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.call),
                            label: Text(l.t('caregiver.callParent')),
                            onPressed: () =>
                                context.read<SafetyProvider>().dial(
                                      child?.trustedContactIds.isNotEmpty
                                          ? ''
                                          : '',
                                    ) != null
                                ? null
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.location_on),
                            label: Text(l.t('caregiver.shareLoc')),
                            onPressed: () =>
                                context.read<SafetyProvider>().startLocationSharing(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ---- Medical information ----
            _CaregiverSection(
              title: l.t('caregiver.medicalInfo'),
              icon: Icons.medical_information,
              colorName: 'red',
              child: Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.medication),
                      title: Text(l.t('caregiver.medication')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showMedicalDialog(
                          context, l.t('caregiver.medication'),
                          child?.medicalInfo ?? ''),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.ambulance),
                      title: Text(l.t('caregiver.allergies')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showMedicalDialog(
                          context, l.t('caregiver.allergies'),
                          child?.allergies ?? ''),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: Text(l.t('caregiver.conditions')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showMedicalDialog(
                          context, l.t('caregiver.conditions'),
                          child?.medicalConditions ?? ''),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(l.t('caregiver.emergencyContacts')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/trusted-contacts'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Communication activity ----
            _CaregiverSection(
              title: l.t('caregiver.commActivity'),
              icon: Icons.forum,
              colorName: 'blue',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                          '${acts.length} ${l.t('caregiver.activities')} ${l.t('report.in')} ${l.t(
                              switch (_period) {
                                _CPeriod.daily => 'report.daily',
                                _CPeriod.weekly => 'report.weekly',
                                _CPeriod.monthly => 'report.monthly',
                              })}',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (acts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                              'No communication activity yet.',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      else
                        ...acts.take(4).map(
                              (CommunicationActivity a) => ListTile(
                                dense: true,
                                leading: Icon(
                                  switch (a.method) {
                                    CommMethod.aac =>
                                        Icons.view_in_ar,
                                    CommMethod.voice => Icons.mic,
                                    CommMethod.sentenceBuilder =>
                                        Icons.text_fields,
                                    CommMethod.needs => Icons.wifi,
                                    CommMethod.emotions =>
                                        Icons.sentiment_satisfied,
                                    CommMethod.routine =>
                                        Icons.checklist,
                                    CommMethod.story => Icons.menu_book,
                                    CommMethod.learning => Icons.school,
                                    CommMethod.safety => Icons.shield,
                                    _ => Icons.chat,
                                  },
                                  size: 18,
                                  color: AppColors.fromName(
                                      switch (a.method) {
                                        CommMethod.aac => 'purple',
                                        CommMethod.voice => 'blue',
                                        CommMethod.sentenceBuilder => 'teal',
                                        CommMethod.needs => 'orange',
                                        CommMethod.emotions => 'yellow',
                                        CommMethod.routine => 'green',
                                        CommMethod.story => 'pink',
                                        CommMethod.learning => 'teal',
                                        CommMethod.safety => 'red',
                                        _ => 'gray',
                                      }),
                                ),
                                title: Text(
                                    a.content ?? l.t('caregiver.activity'),
                                    maxLines: 1),
                                subtitle: Text(
                                    '${a.createdAt?.toString().split(' ')[1]?.substring(0, 5) ?? ""}'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Learning progress ----
            _CaregiverSection(
              title: l.t('caregiver.learningProgress'),
              icon: Icons.school,
              colorName: 'teal',
              child: Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(l.t('caregiver.activitiesDone')),
                      subtitle: Text(
                          '${learning.progress.length} ${l.t('caregiver.activities')} ${l.t('caregiver.completed')}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/learn/progress'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: Text(l.t('caregiver.starsEarned')),
                      subtitle: Text(
                          '${learning.totalStars(childId)} ${l.t('learn.stars')}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/learn/progress'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.play_arrow),
                      title: Text(l.t('caregiver.continueLearning')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/learn'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Accessibility settings ----
            _CaregiverSection(
              title: l.t('caregiver.accessibility'),
              icon: Icons.accessibility,
              colorName: 'purple',
              child: Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.accessibility),
                      title: Text(l.t('settings.a11y')),
                      subtitle: Text(l.t('caregiver.a11ySubtitle')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l.t('a11y.largeButtons')),
                      subtitle: Text(l.t('caregiver.largeBtnsSub')),
                      value: context.watch<SettingsProvider>()
                          .accessibility
                          .largeButtons,
                      onChanged: (_) => context
                          .read<SettingsProvider>()
                          .toggleLargeButtons(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(l.t('a11y.highContrast')),
                      subtitle: Text(l.t('caregiver.highContrastSub')),
                      value: context.watch<SettingsProvider>()
                          .accessibility
                          .highContrast,
                      onChanged: (_) => context
                          .read<SettingsProvider>()
                          .toggleHighContrast(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Quick links ----
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(l.t('caregiver.children')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/parent/child'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.contacts),
                    title: Text(l.t('safety.contacts')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/trusted-contacts'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    title: Text(l.t('caregiver.routines')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/routines'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(l.t('caregiver.stories')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/stories'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(l.t('caregiver.notifications')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notifications'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: Text(l.t('caregiver.camera')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/safety'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune),
              label: Text(l.t('caregiver.appSettings')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showMedicalDialog(
      BuildContext context, String title, String current) async {
    final TextEditingController ctrl =
        TextEditingController(text: current);
    final AppL10n l = context.l10n;
    final bool ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: l.t('caregiver.editHint'),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.t('common.save')),
          ),
        ],
      ),
    );
    if (ok && context.mounted) {
      final SessionProvider session = context.read<SessionProvider>();
      final ChildProfile? child = session.child;
      if (child != null) {
        final LumoraRepository repo = LumoraRepository.instance;
        ChildProfile updated = child.copyWith(
          medicalInfo: ctrl.text.trim().isEmpty
              ? ''
              : ctrl.text.trim(),
          allergies: title == l.t('caregiver.allergies')
              ? ctrl.text.trim()
              : child.allergies,
          medicalConditions: title == l.t('caregiver.conditions')
              ? ctrl.text.trim()
              : child.medicalConditions,
        );
        await repo.saveChild(updated);
        await session.setChild(updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.t('caregiver.medicalSaved'))),
          );
        }
      }
    }
  }
}

class _CaregiverSection extends StatelessWidget {
  const _CaregiverSection({
    required this.title,
    required this.icon,
    required this.colorName,
    required this.child,
  });

  final String title;
  final IconData icon;
  final String colorName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.fromName(colorName);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
