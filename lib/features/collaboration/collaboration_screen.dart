import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// Collaboration: parents invite caregivers/teachers/therapists, choose
/// exactly which data is shared, view their notes and revoke access.
class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {
  Future<void> _invite() async {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final String childId =
        context.read<SessionProvider>().child?.id ?? 'unknown';

    final TextEditingController name = TextEditingController();
    UserRole role = UserRole.teacher;
    bool reports = true;
    bool emotions = false;
    bool routines = false;
    bool assign = true;
    bool notes = true;
    bool alerts = false;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setDialog) =>
            AlertDialog(
          title: Text(l.t('parent.invite')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                      labelText: 'Name / email'),
                ),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration:
                      InputDecoration(labelText: l.t('settings.rolePermissions')),
                  items: <UserRole>[
                    UserRole.caregiver,
                    UserRole.teacher,
                    UserRole.therapist,
                  ]
                      .map((UserRole r) => DropdownMenuItem<UserRole>(
                            value: r,
                            child: Text(l.t('role.${r.nameId}')),
                          ))
                      .toList(),
                  onChanged: (UserRole? r) =>
                      setDialog(() => role = r ?? UserRole.teacher),
                ),
                const SizedBox(height: 8),
                Text(l.t('parent.sharedData',
                    <String, String>{'name': name.text}),
                    style: Theme.of(ctx).textTheme.labelSmall),
                SwitchListTile(
                    dense: true,
                    title: Text(l.t('report.methods')),
                    value: reports,
                    onChanged: (bool v) => setDialog(() => reports = v)),
                SwitchListTile(
                    dense: true,
                    title: Text(l.t('feel.history')),
                    value: emotions,
                    onChanged: (bool v) => setDialog(() => emotions = v)),
                SwitchListTile(
                    dense: true,
                    title: Text(l.t('routine.title')),
                    value: routines,
                    onChanged: (bool v) => setDialog(() => routines = v)),
                SwitchListTile(
                    dense: true,
                    title: Text(l.t('parent.assignedActivities')),
                    value: assign,
                    onChanged: (bool v) => setDialog(() => assign = v)),
                SwitchListTile(
                    dense: true,
                    title: Text(l.t('parent.progressNotes')),
                    value: notes,
                    onChanged: (bool v) => setDialog(() => notes = v)),
                SwitchListTile(
                    dense: true,
                    title: Text(l.t('settings.notifAlerts')),
                    value: alerts,
                    onChanged: (bool v) => setDialog(() => alerts = v)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.t('parent.invite')),
            ),
          ],
        ),
      ),
    );

    if (ok != true || name.text.trim().isEmpty) return;
    await repo.savePermission(CaregiverPermission(
      id: const Uuid().v4(),
      childId: childId,
      invitedUserId: name.text.trim(),
      invitedUserName: name.text.trim(),
      role: role,
      canViewReports: reports,
      canViewEmotions: emotions,
      canViewRoutines: routines,
      canAssignActivities: assign,
      canWriteNotes: notes,
      canReceiveAlerts: alerts,
      status: 'active',
      inviteCode: 'LUMORA-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      createdAt: DateTime.now(),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final List<CaregiverPermission> permissions = repo.getPermissions();
    final List<CaregiverNote> notes = repo
        .getNotes()
        .where((CaregiverNote n) =>
            n.noteType == 'teacher' || n.noteType == 'therapist')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('parent.collaboration')),
        // Teacher/therapist collaboration screens keep the sign-out in reach.
        actions: const <Widget>[SignOutButton()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'invite',
        onPressed: _invite,
        child: const Icon(Icons.person_add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l.t('parent.permissions'),
              style: Theme.of(context).textTheme.titleMedium),
          if (permissions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.t('common.empty'),
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...permissions.map(
              (CaregiverPermission p) => Card(
                child: ListTile(
                  leading: Icon(
                    p.role == UserRole.teacher
                        ? Icons.school
                        : Icons.medical_services,
                  ),
                  title: Text(p.invitedUserName),
                  subtitle: Text(
                    '${l.t('role.${p.role.nameId}')} · '
                    '${p.isActive ? l.t('common.enabled') : l.t('common.disabled')}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String action) async {
                      switch (action) {
                        case 'revoke':
                          await repo.savePermission(
                              p.copyWith(status: 'revoked'));
                          break;
                        case 'reactivate':
                          await repo.savePermission(
                              p.copyWith(status: 'active'));
                          break;
                        case 'delete':
                          await repo.deletePermission(p.id);
                          break;
                      }
                      if (context.mounted) setState(() {});
                    },
                    itemBuilder: (BuildContext ctx) =>
                        <PopupMenuEntry<String>>[
                      if (p.isActive)
                        const PopupMenuItem<String>(
                            value: 'revoke', child: Text('Revoke access'))
                      else
                        const PopupMenuItem<String>(
                            value: 'reactivate',
                            child: Text('Reactivate')),
                      const PopupMenuItem<String>(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(l.t('parent.progressNotes'),
              style: Theme.of(context).textTheme.titleMedium),
          if (notes.isEmpty)
            Text(l.t('parent.noNotes'),
                style: Theme.of(context).textTheme.bodySmall)
          else
            ...notes.map(
              (CaregiverNote n) => Card(
                child: ListTile(
                  leading: const Icon(Icons.sticky_note_2),
                  title: Text(n.text),
                  subtitle: Text(n.authorName),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(l.t('parent.inviteHint'),
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
