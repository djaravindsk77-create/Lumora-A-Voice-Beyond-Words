import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';

/// Welcome screen with tagline and the three entry paths.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(l.t('app.name'), style: t.displayMedium),
              const SizedBox(height: 6),
              Text(
                l.t('app.tagline'),
                style: t.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/role-select'),
                  child: Text(l.t('onboarding.getStarted')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.science),
                  onPressed: () => context.push('/login?demo=1'),
                  label: Text(l.t('onboarding.demoButton')),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(l.t('onboarding.haveAccount')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
