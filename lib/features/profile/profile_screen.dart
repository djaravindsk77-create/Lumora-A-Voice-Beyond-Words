import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_role.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/sign_out_button.dart';

/// Profile screen for the signed-in user: name, role, role switching
/// (demo), settings shortcuts and sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final SettingsProvider sp = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l.t('profile.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0x295B7FDB),
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    session.user?.name ?? 'Demo User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    session.user?.email ?? '-',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(l.t('role.${session.role.nameId}')),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l.t('profile.switchRole'),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values
                .map((UserRole r) => ChoiceChip(
                      label: Text(l.t('role.${r.nameId}')),
                      selected: session.role == r,
                      onSelected: (bool sel) async {
                        if (sel) {
                          await session.setRole(r);
                          if (r == UserRole.child) {
                            await session.startDemo(role: r);
                            if (context.mounted) {
                              // Replace the stack so Back does not return here.
                              context.go('/child-home');
                            }
                          } else if (context.mounted) {
                            context.go('/parent-dashboard');
                          }
                        }
                      },
                    ))
                .toList(),
          ),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: Text(l.t('parent.children')),
            subtitle: Text(session.child?.name ?? '-'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/parent/child'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.t('settings.language')),
            subtitle: Text(AppLocales.displayName(
                Locale(sp.settings.languageCode))),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language'),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility),
            title: Text(l.t('settings.a11y')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 28),
          if (session.isChild)
            ListTile(
              leading: const Icon(Icons.shield),
              title: Text(l.t('safety.lostMode')),
              subtitle: Text(l.t('safety.lostModeBody')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/lost-mode'),
            ),
          // Shared sign-out: confirms, stops the siren, clears the saved
          // session and returns to Welcome (no going back into the account).
          FilledButton.tonalIcon(
            icon: const Icon(Icons.logout),
            label: Text(l.t('auth.signOut')),
            onPressed: () => confirmSignOut(context),
          ),
        ],
      ),
    );
  }
}
