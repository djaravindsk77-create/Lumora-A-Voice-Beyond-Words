import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import '../providers/session_provider.dart';

/// Confirms the sign-out, then clears the saved session and returns to the
/// Welcome screen. Used by every role (child, parent, teacher, therapist and
/// caregiver) so there is always one honest way out of the app.
Future<void> confirmSignOut(BuildContext context) async {
  final AppL10n l = context.l10n;
  final SessionProvider session = context.read<SessionProvider>();

  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(l.t('profile.logoutConfirm')),
      content: Text(l.t('auth.signOut')),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l.t('common.cancel')),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.logout),
          label: Text(l.t('auth.signOut')),
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  await session.signOut();
  if (context.mounted) {
    // Replace the stack: Back must not return into the signed-out session.
    context.go('/welcome');
  }
}

/// App-bar sign-out action. Drop it into the `actions` of any role's screen.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.t('auth.signOut'),
      icon: const Icon(Icons.logout),
      onPressed: () => confirmSignOut(context),
    );
  }
}

/// Sign-out row for list-based screens (profile, settings).
class SignOutTile extends StatelessWidget {
  const SignOutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: AppColors.error),
      title: Text(
        context.l10n.t('auth.signOut'),
        style: const TextStyle(color: AppColors.error),
      ),
      onTap: () => confirmSignOut(context),
    );
  }
}
