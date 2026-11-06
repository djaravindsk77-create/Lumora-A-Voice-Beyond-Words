import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';

/// Splash screen: brief branded pause then routes to onboarding or home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final bool onboarded = context
              .read<SettingsProvider>()
              .settings
              .onboardingComplete;
      final bool hasSession =
          context.read<SessionProvider>().user != null;
      if (!mounted) return;
      // A restored session goes straight to the right home screen: the child
      // role to Child Mode, every adult role to the dashboard.
      if (hasSession) {
        context.go(context.read<SessionProvider>().homeRoute);
        return;
      }
      // Replace the stack so Back from Welcome exits instead of re-showing Splash.
      context.go(onboarded ? '/welcome-back' : '/welcome');
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_sunny,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Lumora',
              style: t.displayMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.t('app.tagline'),
              style: t.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
