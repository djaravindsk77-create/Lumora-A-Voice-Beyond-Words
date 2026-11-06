import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../models/child_profile.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';

/// Child profile setup (name, age, avatar) shown after registration.
class ChildProfileSetupScreen extends StatefulWidget {
  const ChildProfileSetupScreen({super.key});

  @override
  State<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState extends State<ChildProfileSetupScreen> {
  final TextEditingController _name = TextEditingController();
  int _age = 6;
  String _avatar = 'sun';

  static const List<({String key, IconData icon, String color})> _avatars =
      <({String key, IconData icon, String color})>[
    (key: 'sun', icon: Icons.wb_sunny, color: 'yellow'),
    (key: 'star', icon: Icons.star, color: 'blue'),
    (key: 'heart', icon: Icons.favorite, color: 'pink'),
    (key: 'cat', icon: Icons.cruelty_free, color: 'orange'),
    (key: 'bloom', icon: Icons.local_florist, color: 'teal'),
    (key: 'rocket', icon: Icons.rocket_launch, color: 'purple'),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('common.requiredField'))),
      );
      return;
    }
    final LumoraRepository repo = LumoraRepository.instance;
    await repo.init();
    final ChildProfile child = ChildProfile(
      id: repo.local.newId(),
      name: name,
      age: _age,
      avatarKey: _avatar,
    );
    await repo.saveChild(child);
    if (!mounted) return;
    await context.read<SessionProvider>().setChild(child);
    if (!mounted) return;
    FeedbackService.success();
    // Replace the stack: Back from Setup Complete must not return to the form.
    context.go('/setup-complete');
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.t('setup.childTitle'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l.t('setup.childName'),
                prefixIcon: const Icon(Icons.face),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            Text(l.t('setup.childAge'),
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _age.toDouble(),
              min: 2,
              max: 18,
              divisions: 16,
              label: '$_age',
              onChanged: (double v) => setState(() => _age = v.round()),
            ),
            const SizedBox(height: 8),
            Text(l.t('setup.chooseAvatar'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map(
                (a) {
                  final Color color = AppColors.fromName(a.color);
                  final bool selected = _avatar == a.key;
                  return InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => setState(() => _avatar = a.key),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: selected ? 0.35 : 0.14),
                        border: Border.all(
                          color: selected ? color : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Icon(a.icon, color: color, size: 32),
                    ),
                  );
                },
              ).toList(),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              child: Text(l.t('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Completion screen offering Child Home or Parent Dashboard.
class SetupCompleteScreen extends StatelessWidget {
  const SetupCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(Icons.celebration,
                  size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                l.t('setup.finishTitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                l.t('setup.finishBody'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: () => context.push('/child-home'),
                child: Text(l.t('setup.goChildHome')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/parent-dashboard'),
                child: Text(l.t('setup.goDashboard')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
