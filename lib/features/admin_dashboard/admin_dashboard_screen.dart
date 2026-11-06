import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/barrel.dart';
import '../../providers/learning_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/safety_provider.dart';
import '../../providers/communication_provider.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../core/theme/app_colors.dart' as app_colors;
import '../../widgets/barrel.dart';

/// Admin Dashboard: organisation-level overview for the administrator role.
///
/// Shows total users and children, lets the admin manage therapists and
/// caregivers (invite / revoke / permissions), view user accounts, see
/// overall app activity and access app-wide settings.
///
/// Reuses the existing repository + models — no new storage or backend.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

enum _AdminPeriod { daily, weekly, monthly }

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminPeriod _period = _AdminPeriod.weekly;
  final GlobalKey<_AdminUserListState> _userListKey = GlobalKey<_AdminUserListState>();
  final GlobalKey<_AdminManageColleaguesState> _colleaguesKey = GlobalKey<_AdminManageColleaguesState>();
  final GlobalKey<_AdminActivityCardState> _activityKey = GlobalKey<_AdminActivityCardState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SessionProvider session = context.read<SessionProvider>();
      if (session.role != UserRole.administrator) return;
      // Pre-load any lazy providers that the admin view consumes.
      final RoutineProvider routines = context.read<RoutineProvider>();
      final SafetyProvider safety = context.read<SafetyProvider>();
      final CommunicationProvider comm = context.read<CommunicationProvider>();
      final LearningProvider learning = context.read<LearningProvider>();
      await routines.load(session.user?.id ?? '');
      await safety.load(session.child?.id ?? '');
      await comm.load(session.child?.id ?? '');
      await learning.load(session.child?.id ?? '');
    });
  }  Future<void> _refreshSection(GlobalKey key) async {
    final dynamic target = key.currentState;      if (target is _AdminManageColleaguesRefresher ||
        target is _AdminUserListRefresher ||
        target is _AdminActivityCardRefresher) {
      await target.refresh();
      return;
    }
    if (mounted) setState(() {});
  }

  int _days(_AdminPeriod p) {
    switch (p) {
      case _AdminPeriod.daily:
        return 1;
      case _AdminPeriod.weekly:
        return 7;
      case _AdminPeriod.monthly:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final LumoraRepository repo = LumoraRepository.instance;

    final List<UserModel> allUsers = repo.getUsers();
    final List<ChildProfile> allChildren = repo.getChildren();
    final List<CaregiverNote> allNotes =
        repo.getNotes().where((CaregiverNote n) => !n.isPrivate).toList();
    final List<CaregiverPermission> allPerms = repo.getPermissions();

    final int totalUsers = allUsers.length;
    final int totalChildren = allChildren.length;

    final int therapistCount =
        allUsers.where((UserModel u) => u.role == UserRole.therapist).length +
            allPerms.where((CaregiverPermission p) =>
                p.role == UserRole.therapist && p.isActive).length;
    final int caregiverCount =
        allUsers.where((UserModel u) => u.role == UserRole.caregiver).length +
            allPerms.where((CaregiverPermission p) =>
                p.role == UserRole.caregiver && p.isActive).length;
    final int teacherCount =
        allUsers.where((UserModel u) => u.role == UserRole.teacher).length +
            allPerms.where((CaregiverPermission p) =>
                p.role == UserRole.teacher && p.isActive).length;

    // Activity counts for the selected period.
    final int _periodDays = _days(_period);
    final int recentActivities = allNotes
        .where((CaregiverNote n) =>
            n.createdAt != null &&
            DateTime.now().difference(n.createdAt!).inDays < periodDays)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('admin.dashboard')),
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
            // Admin header.
            Card(
              color: AppColors.primary.withValues(alpha: 0.10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child:
                          Icon(Icons.admin_panel_settings,
                              color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.t('admin.welcome'),
                            style:
                                Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            session.user?.email ?? '-',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(l.t('role.administrator')),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_AdminPeriod>(
              segments: <ButtonSegment<_AdminPeriod>>[
                ButtonSegment<_AdminPeriod>(
                    value: _AdminPeriod.daily,
                    label: Text(l.t('report.daily'))),
                ButtonSegment<_AdminPeriod>(
                    value: _AdminPeriod.weekly,
                    label: Text(l.t('report.weekly'))),
                ButtonSegment<_AdminPeriod>(
                    value: _AdminPeriod.monthly,
                    label: Text(l.t('report.monthly'))),
              ],
              selected: <_AdminPeriod>{_period},
              onSelectionChanged: (Set<_AdminPeriod> s) {
                setState(() => _period = s.first);
                // Refresh the activity card with the new period.
                _refreshSection(_activityKey);
              },
            ),
            const SizedBox(height: 12),
            // Stats grid.
            Text(
                l.t('admin.overview'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: <Widget>[
                StatTile(
                  label: l.t('admin.totalUsers'),
                  value: '$totalUsers',
                  icon: Icons.people,
                  colorName: 'blue',
                ),
                StatTile(
                  label: l.t('admin.totalChildren'),
                  value: '$totalChildren',
                  icon: Icons.child_care,
                  colorName: 'teal',
                ),
                StatTile(
                  label: l.t('admin.therapists'),
                  value: '$therapistCount',
                  icon: Icons.healing,
                  colorName: 'purple',
                ),
                StatTile(
                  label: l.t('admin.caregivers'),
                  value: '$caregiverCount',
                  icon: Icons.volunteer_activism,
                  colorName: 'orange',
                ),
                StatTile(
                  label: l.t('admin.teachers'),
                  value: '$teacherCount',
                  icon: Icons.school,
                  colorName: 'green',
                ),
                StatTile(
                  label: l.t('admin.recentNotes'),
                  value: '$recentActivities',
                  icon: Icons.sticky_note_2,
                  colorName: 'yellow',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Manage therapists & caregivers ----
            _AdminSection(
              title: l.t('admin.manageTherapistsCaregivers'),
              icon: Icons.people_outline,
              colorName: 'purple',
              child: _AdminManageColleagues(
                therapists: allUsers
                    .where((UserModel u) => u.role == UserRole.therapist)
                    .toList(),
                caregivers: allUsers
                    .where((UserModel u) => u.role == UserRole.caregiver)
                    .toList(),
                teacherPerms: allPerms
                    .where((CaregiverPermission p) =>
                        p.role == UserRole.teacher && p.isActive)
                    .toList(),
                therapistPerms: allPerms
                    .where((CaregiverPermission p) =>
                        p.role == UserRole.therapist && p.isActive)
                    .toList(),
                caregiverPerms: allPerms
                    .where((CaregiverPermission p) =>
                        p.role == UserRole.caregiver && p.isActive)
                    .toList(),
              ),
            ),

            // ---- User account management ----
            _AdminSection(
              title: l.t('admin.userAccounts'),
              icon: Icons.account_circle_outlined,
              colorName: 'blue',
              child: _AdminUserList(users: allUsers),
            ),

            // ---- Overall app activity ----
            _AdminSection(
              title: l.t('admin.appActivity'),
              icon: Icons.bar_chart,
              colorName: 'green',
              child: _AdminActivityCard(
                notesCount: allNotes.length,
                recentNotes: allNotes.take(5).toList(),
                childrenCount: totalChildren,                periodDays: periodDays,
      periodLabel: l.t(
                    switch (_period) {
                      _AdminPeriod.daily => 'report.daily',
                      _AdminPeriod.weekly => 'report.weekly',
                      _AdminPeriod.monthly => 'report.monthly',
                    }),
              ),
            ),
            const SizedBox(height: 16),
            // ---- App settings shortcut ----
            _AdminSection(
              title: l.t('admin.settings'),
              icon: Icons.tune,
              colorName: 'orange',
              child: Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.accessibility),
                      title: Text(l.t('settings.a11y')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l.t('settings.language')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/language'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(l.t('settings.notifications')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/notifications'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: Text(l.t('settings.privacy')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: Text(l.t('admin.appSettings')),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ---- Admin section card ----

class _AdminSection extends StatelessWidget {
  const _AdminSection({
    super.key,
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
    final Color color = app_colors.AppColors.fromName(colorName);
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(
                          color: color,
                        ),
                  ),
                ),
                const Spacer(),
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

// ---- Manage therapists & caregivers ----

mixin _AdminManageColleaguesRefresher on State<_AdminManageColleagues> {
  Future<void> refresh() async {}
}

mixin _AdminUserListRefresher on State<_AdminUserList> {
  Future<void> refresh() async {}
}

mixin _AdminActivityCardRefresher on State<_AdminActivityCard> {
  Future<void> refresh() async {}
}

class _AdminManageColleagues extends StatefulWidget {
  const _AdminManageColleagues({
    required this.therapists,
    required this.caregivers,
    required this.teacherPerms,
    required this.therapistPerms,
    required this.caregiverPerms,
  });

  final List<UserModel> therapists;
  final List<UserModel> caregivers;
  final List<CaregiverPermission> teacherPerms;
  final List<CaregiverPermission> therapistPerms;
  final List<CaregiverPermission> caregiverPerms;

  @override
  State<_AdminManageColleagues> createState() =>
      _AdminManageColleaguesState();
}

class _AdminManageColleaguesState extends State<_AdminManageColleagues>
    with _AdminManageColleaguesRefresher {
  late List<UserModel> _therapists;
  late List<UserModel> _caregivers;
  late List<CaregiverPermission> _teacherPerms;
  late List<CaregiverPermission> _therapistPerms;
  late List<CaregiverPermission> _caregiverPerms;

  @override
  void initState() {
    super.initState();
    _syncLists();
  }

  void _syncLists() {
    _therapists = widget.therapists;
    _caregivers = widget.caregivers;
    _teacherPerms = widget.teacherPerms;
    _therapistPerms = widget.therapistPerms;
    _caregiverPerms = widget.caregiverPerms;
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;

    return Column(
      children: <Widget>[
        // Therapists.
        Row(
          children: <Widget>[
            const Icon(Icons.healing, size: 20, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${l.t('admin.therapists')}: ${teachersCount + _therapists.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showInviteDialog(context, UserRole.therapist),
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(l.t('admin.invite')),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_therapists.isEmpty && _therapistPerms.isEmpty)
          Text(
            l.t('admin.noTherapists'),
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ..._therapists.map(
            (UserModel u) => _AdminColleagueTile(
              name: u.name,
              email: u.email,
              role: UserRole.therapist,
              isActive: true,
            ),
          ),
        if (_therapistPerms.isNotEmpty)
          ..._therapistPerms.map(
            (CaregiverPermission p) => _AdminColleagueTile(
              name: p.invitedUserName,
              email: '',
              role: UserRole.therapist,
              isActive: p.isActive,
              inviteCode: p.inviteCode,
            ),
          ),
        const Divider(),

        // Caregivers.
        Row(
          children: <Widget>[
            const Icon(Icons.volunteer_activism,
                size: 20, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${l.t('admin.caregivers')}: ${_caregivers.length + _caregiverPerms.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showInviteDialog(context, UserRole.caregiver),
              icon: const Icon(Icons.person_add, size: 18),
              label: Text(l.t('admin.invite')),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_caregivers.isEmpty && _caregiverPerms.isEmpty)
          Text(
            l.t('admin.noCaregivers'),
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ..._caregivers.map(
            (UserModel u) => _AdminColleagueTile(
              name: u.name,
              email: u.email,
              role: UserRole.caregiver,
              isActive: true,
            ),
          ),
        if (_caregiverPerms.isNotEmpty)
          ..._caregiverPerms.map(
            (CaregiverPermission p) => _AdminColleagueTile(
              name: p.invitedUserName,
              email: '',
              role: UserRole.caregiver,
              isActive: p.isActive,
              inviteCode: p.inviteCode,
            ),
          ),

        const Divider(height: 24),

        // Teachers (visible to admin for oversight).
        Row(
          children: <Widget>[
            const Icon(Icons.school, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${l.t('admin.teachers')}: ${_teacherPerms.length} shared',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_teacherPerms.isEmpty)
          Text(
            l.t('admin.noTeachers'),
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ..._teacherPerms.map(
            (CaregiverPermission p) => _AdminColleagueTile(
              name: p.invitedUserName,
              email: '',
              role: UserRole.teacher,
              isActive: p.isActive,
              inviteCode: p.inviteCode,
            ),
          ),
      ],
    );
  }

  int get teachersCount =>
      _therapists.where((UserModel u) => u.role == UserRole.teacher).length;

  Future<void> _showInviteDialog(BuildContext context, UserRole role) async {
    final TextEditingController nameCtrl = TextEditingController();
    final bool ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title:
            Text(l.t('admin.invite') + ' ' + l.t('role.${role.nameId}')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l.t('admin.inviteeName')),
            ),
          ],
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
      final LumoraRepository repo = LumoraRepository.instance;
      final String code = 'INV-001';
      final CaregiverPermission perm = CaregiverPermission(
        id: 'perm-001',
        childId: repo.getChildren().firstOrNull?.id ?? '',
        invitedUserId: 'invited-$role-001',
        invitedUserName: nameCtrl.text.trim().isEmpty
            ? l.t('admin.inviteeDefault')
            : nameCtrl.text.trim(),
        role: role,
        canViewReports: role == UserRole.therapist,
        canViewEmotions: role == UserRole.therapist,
        canViewRoutines: role == UserRole.caregiver,
        canAssignActivities: role == UserRole.teacher,
        canWriteNotes: role == UserRole.therapist ||
            role == UserRole.caregiver,
        canReceiveAlerts: true,
        inviteCode: code,
      );
      await repo.savePermission(perm);
      _syncLists();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.t('admin.inviteSent'))),
        );
      }
    }
  }
}

class _AdminColleagueTile extends StatelessWidget {
  const _AdminColleagueTile({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.inviteCode,
  });

  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? inviteCode;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final String label = inviteCode != null ? '${name} · $inviteCode' : name;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.10),
        child: Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          color: isActive ? AppColors.primary : AppColors.error,
          size: 18,
        ),
      ),
      title: Text(label),
      subtitle:
          Text(email.isNotEmpty ? email : l.t('role.${role.nameId}')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isActive)
            TextButton(
              onPressed: () => _revoke(context),
              child: Text(l.t('parent.revoke')),
            ),
          if (isActive && inviteCode != null)
            TextButton(
              onPressed: () => _resendInvite(context),
              child: Text(l.t('admin.resendInvite')),
            ),
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context) async {
    final LumoraRepository repo = LumoraRepository.instance;
    await repo.deletePermission(
        'perm-${name.toLowerCase().replaceAll(' ', '-')}');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('admin.revoked'))),
      );
    }
  }

  Future<void> _resendInvite(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('admin.inviteResent'))),
      );
    }
  }
}

// ---- User account list ----

class _AdminUserList extends StatefulWidget {
  const _AdminUserList({required this.users});

  final List<UserModel> users;

  @override
  State<_AdminUserList> createState() => _AdminUserListState();
}

class _AdminUserListState extends State<_AdminUserList>
    with _AdminUserListRefresher {
  late List<UserModel> _users;

  @override
  void initState() {
    super.initState();
    _users = widget.users;
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Column(
      children: _users.map((UserModel u) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.fromName(
                u.role == UserRole.child
                    ? 'yellow'
                    : u.role == UserRole.parent
                        ? 'blue'
                        : u.role == UserRole.therapist
                            ? 'purple'
                            : u.role == UserRole.caregiver
                                ? 'orange'
                                : u.role == UserRole.teacher
                                    ? 'green'
                                    : 'red'),
            child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?'),
          ),
          title: Text(u.name),
          subtitle:
              Text(u.email.isNotEmpty ? u.email : l.t('role.${u.role.nameId}')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Chip(
                label: Text(l.t('role.${u.role.nameId}')),
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                visualDensity: VisualDensity.compact,
              ),
              if (u.demo)
                const Chip(
                  label: Text('demo'),
                  backgroundColor:
                      AppColors.error.withValues(alpha: 0.10),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          onTap: () => _showUserDetail(context, u),
        );
      }).toList(),
    );
  }

  Future<void> _showUserDetail(BuildContext context, UserModel u) async {
    final AppL10n l = context.l10n;
    await showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(u.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${l.t('auth.email')}: ${u.email ?? '-'}'),
            const SizedBox(height: 4),
            Text('${l.t('role.title')}: ${l.t('role.${u.role.nameId}')}'),
            if (u.demo)
              Text(
                  ' ${l.t('auth.demo')}',
                  style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.t('common.close')),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> refresh() async {
    _users = widget.users;
    setState(() {});
  }
}

// ---- Activity card ----

class _AdminActivityCard extends StatefulWidget {
  const _AdminActivityCard({
    required this.notesCount,
    required this.recentNotes,
    required this.childrenCount,
    required this.periodDays,
    required this.periodLabel,
  });

  final int notesCount;
  final List<CaregiverNote> recentNotes;
  final int childrenCount;
  final int periodDays;
  final String periodLabel;

  @override
  State<_AdminActivityCard> createState() => _AdminActivityCardState();
}

class _AdminActivityCardState extends State<_AdminActivityCard>
    with _AdminActivityCardRefresher {
  int _notesCount;
  List<CaregiverNote> _recentNotes;
  int _childrenCount;
  int _periodDays;
  String _periodLabel;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    _notesCount = widget.notesCount;
    _recentNotes = widget.recentNotes;
    _childrenCount = widget.childrenCount;
    _periodDays = widget.periodDays;
    _periodLabel = widget.periodLabel;
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  '${widget.notesCount} ${l.t('parent.notes').toLowerCase()} in ${widget.periodLabel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${widget.childrenCount} ${l.t('parent.children').toLowerCase()} across ${widget.periodDays} ${l.t('report.period')}'),
            if (widget.recentNotes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    'No notes yet.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              ...widget.recentNotes.take(3).map(
                    (CaregiverNote n) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.sticky_note_2, size: 18),
                      title: Text(n.text, maxLines: 1),
                      subtitle: Text(
                          '${n.authorName} (${n.authorRole})'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> refresh() async {
    _sync();
    setState(() {});
  }
}
