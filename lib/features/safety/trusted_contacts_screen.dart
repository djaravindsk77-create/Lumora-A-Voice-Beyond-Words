import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/barrel.dart';
import '../../providers/safety_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/barrel.dart';

/// Trusted Contacts: add/edit/remove, set primary, permission level,
/// notification preference and revoke access - all parent-controlled.
class TrustedContactsScreen extends StatelessWidget {
  const TrustedContactsScreen({super.key});

  Future<void> _addOrEdit(BuildContext context, [TrustedContact? existing]) async {
    final AppL10n l = context.l10n;
    final SafetyProvider safety = context.read<SafetyProvider>();
    final String childId =
        context.read<SessionProvider>().child?.id ?? 'unknown';

    final TextEditingController name =
        TextEditingController(text: existing?.name ?? '');
    final TextEditingController phone =
        TextEditingController(text: existing?.phone ?? '');
    final TextEditingController email =
        TextEditingController(text: existing?.email ?? '');
    String relationship = existing?.relationship ?? 'parent';
    String permission = existing?.permissionLevel ?? 'viewer';
    String notifPref = existing?.notificationPreference ?? 'alerts';

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setDialog) =>
            AlertDialog(
          title: Text(existing == null
              ? l.t('safety.addContact')
              : l.t('common.edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  decoration:
                      InputDecoration(labelText: l.t('safety.contactName')),
                ),
                TextField(
                  controller: phone,
                  decoration:
                      InputDecoration(labelText: l.t('safety.phone')),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: email,
                  decoration:
                      InputDecoration(labelText: l.t('safety.email')),
                  keyboardType: TextInputType.emailAddress,
                ),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  decoration: InputDecoration(
                      labelText: l.t('safety.relationship')),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'parent', child: Text('Parent')),
                    DropdownMenuItem<String>(
                        value: 'primaryCaregiver', child: Text('Primary caregiver')),
                    DropdownMenuItem<String>(
                        value: 'secondaryCaregiver',
                        child: Text('Secondary caregiver')),
                    DropdownMenuItem<String>(value: 'teacher', child: Text('Teacher')),
                    DropdownMenuItem<String>(
                        value: 'therapist', child: Text('Therapist')),
                    DropdownMenuItem<String>(
                        value: 'emergency', child: Text('Emergency contact')),
                  ],
                  onChanged: (String? v) =>
                      setDialog(() => relationship = v ?? 'parent'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: permission,
                  decoration: InputDecoration(
                      labelText: l.t('safety.permissionLevel')),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'viewer', child: Text('Viewer')),
                    DropdownMenuItem<String>(value: 'editor', child: Text('Editor')),
                    DropdownMenuItem<String>(value: 'full', child: Text('Full')),
                  ],
                  onChanged: (String? v) =>
                      setDialog(() => permission = v ?? 'viewer'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: notifPref,
                  decoration: InputDecoration(
                      labelText: l.t('safety.notifPref')),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'none', child: Text('None')),
                    DropdownMenuItem<String>(value: 'alerts', child: Text('Alerts')),
                    DropdownMenuItem<String>(value: 'all', child: Text('All')),
                  ],
                  onChanged: (String? v) =>
                      setDialog(() => notifPref = v ?? 'alerts'),
                ),
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
              child: Text(l.t('common.save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true || name.text.trim().isEmpty) return;
    final TrustedContact contact = TrustedContact(
      id: existing?.id ?? const Uuid().v4(),
      childId: childId,
      name: name.text.trim(),
      relationship: relationship,
      phone: phone.text.trim(),
      email: email.text.trim().isEmpty ? null : email.text.trim(),
      permissionLevel: permission,
      notificationPreference: notifPref,
      isPrimary: existing?.isPrimary ?? false,
      hasAccess: existing?.hasAccess ?? true,
    );
    await safety.saveContact(contact);
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SafetyProvider safety = context.watch<SafetyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('safety.contacts')),
        actions: const <Widget>[SignOutButton()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-contact',
        onPressed: () => _addOrEdit(context),
        child: const Icon(Icons.person_add),
      ),
      body: safety.contacts.isEmpty
          ? EmptyView(
              title: l.t('safety.noContacts'),
              icon: Icons.contacts,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: safety.contacts.length,
              itemBuilder: (BuildContext context, int i) {
                final TrustedContact c = safety.contacts[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.isPrimary
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : AppColors.outline.withValues(alpha: 0.2),
                      child: Text(c.name.isNotEmpty
                          ? c.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(
                      '${c.name}${c.isPrimary ? '  ·  ${l.t('safety.primary')}' : ''}',
                    ),
                    subtitle: Text(
                        '${c.relationship} · ${c.phone}${c.hasAccess ? '' : ' · ${l.t('safety.revoke')}d'}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String action) async {
                        switch (action) {
                          case 'edit':
                            await _addOrEdit(context, c);
                            break;
                          case 'primary':
                            await safety.setPrimary(c);
                            break;
                          case 'revoke':
                            await safety.revokeAccess(c);
                            break;
                          case 'delete':
                            await safety.deleteContact(c);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext ctx) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                            value: 'edit', child: Text('Edit')),
                        const PopupMenuItem<String>(
                            value: 'primary', child: Text('Set as primary')),
                        const PopupMenuItem<String>(
                            value: 'revoke', child: Text('Revoke access')),
                        const PopupMenuItem<String>(
                            value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
