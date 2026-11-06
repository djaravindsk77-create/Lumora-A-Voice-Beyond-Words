import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/user_role.dart';

/// Role selection: who is using the app right now.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const Map<UserRole, ({IconData icon, String color})> _visuals =
      <UserRole, ({IconData icon, String color})>{
    UserRole.child: (icon: Icons.face, color: 'yellow'),
    UserRole.parent: (icon: Icons.family_restroom, color: 'blue'),
    UserRole.caregiver: (icon: Icons.volunteer_activism, color: 'teal'),
    UserRole.teacher: (icon: Icons.school, color: 'purple'),
    UserRole.therapist: (icon: Icons.medical_services, color: 'green'),
    UserRole.administrator: (icon: Icons.manage_accounts, color: 'gray'),
  };

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final TextTheme t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.t('onboarding.roleTitle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              l.t('onboarding.roleSubtitle'),
              style: t.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...UserRole.values.map(
              (UserRole role) {
                final v = _visuals[role]!;
                final Color color = AppColors.fromName(v.color);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        FeedbackService.tap();
                        context.push('/language?role=${role.nameId}');
                      },
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.2),
                        child: Icon(v.icon, color: color),
                      ),
                      title: Text(l.t('role.${role.nameId}')),
                      subtitle: Text(l.t('role.${role.nameId}Desc')),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
