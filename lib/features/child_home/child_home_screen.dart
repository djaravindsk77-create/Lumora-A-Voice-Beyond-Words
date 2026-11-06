import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/child_profile.dart';
import '../../providers/routine_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';

/// Child Home: the large-button dashboard. Cards are ordered and filtered
/// by the child's homeLayout (managed by parents) and favorites first row.
class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  static const Map<String, ({IconData icon, String color, String labelKey})>
      _catalog = <String, ({IconData icon, String color, String labelKey})>{
    'talk': (icon: Icons.record_voice_over, color: 'blue', labelKey: 'home.talk'),
    'pictures':
        (icon: Icons.grid_view, color: 'purple', labelKey: 'home.pictures'),
    'needs':
        (icon: Icons.front_hand, color: 'orange', labelKey: 'home.myNeeds'),
    'feelings': (
      icon: Icons.sentiment_satisfied,
      color: 'yellow',
      labelKey: 'home.myFeelings'
    ),
    'learn': (
      icon: Icons.extension,
      color: 'teal',
      labelKey: 'home.learnPlay'
    ),
    'routine': (icon: Icons.checklist, color: 'green', labelKey: 'home.myRoutine'),
    'calm': (icon: Icons.spa, color: 'teal', labelKey: 'home.calmSpace'),
    'safety': (icon: Icons.shield, color: 'red', labelKey: 'home.safety'),
    'progress': (icon: Icons.insights, color: 'purple', labelKey: 'home.myProgress'),
    'profile': (icon: Icons.person, color: 'gray', labelKey: 'common.profile'),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ChildProfile? child = context.read<SessionProvider>().child;
      if (child != null) {
        context.read<RoutineProvider>().load(child.id);
      }
    });
  }

  String _greeting(BuildContext context) {
    final int hour = DateTime.now().hour;
    final AppL10n l = context.l10n;
    if (hour < 12) return l.t('home.greetingMorning');
    if (hour < 17) return l.t('home.greetingAfternoon');
    return l.t('home.greetingEvening');
  }

  Future<void> _open(String key) async {
    // Push so each feature screen gets a working Back button to Home.
    switch (key) {
      case 'talk':
        unawaited(context.push('/voice'));
        break;
      case 'pictures':
        unawaited(context.push('/aac'));
        break;
      case 'needs':
        unawaited(context.push('/needs'));
        break;
      case 'feelings':
        unawaited(context.push('/emotions'));
        break;
      case 'learn':
        unawaited(context.push('/learn'));
        break;
      case 'routine':
        unawaited(context.push('/routines'));
        break;
      case 'calm':
        unawaited(context.push('/calm'));
        break;
      case 'safety':
        unawaited(context.push('/safety'));
        break;
      case 'progress':
        unawaited(context.push('/tracker'));
        break;
      case 'profile':
        unawaited(context.push('/profile'));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final ChildProfile? child = session.child;
    final RoutineProvider routines = context.watch<RoutineProvider>();

    if (session.loading) {
      return const Scaffold(body: LoadingView());
    }
    if (child == null) {
      return Scaffold(
        body: EmptyView(
          title: l.t('common.empty'),
          subtitle: l.t('auth.createChild'),
          icon: Icons.face,
          actionLabel: l.t('auth.createChild'),
          onAction: () => context.push('/child-setup'),
        ),
      );
    }

    final List<String> layout = child.homeLayout;
    final double buttonHeight = child.largeButtons ? 132.0 : 104.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            _AvatarBadge(avatarKey: child.avatarKey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_greeting(context)}, ${child.name}!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: l.t('home.audioGreeting'),
            icon: const Icon(Icons.music_note),
            onPressed: () => TtsService.instance
                .speak('${_greeting(context)}, ${child.name}!'),
          ),
          IconButton(
            tooltip: l.t('common.notifications'),
            icon: const Icon(Icons.notifications),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: l.t('home.customize'),
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/parent/home-layout'),
          ),
          // Child mode also gets a direct way out of the account.
          const SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  // Quick help button.
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.emergency, size: 32),
                      label: Text(
                        l.t('home.quickHelp'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () => context.push('/safety'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Routine preview.
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(l.t('home.whatsNext')),
                      subtitle: Text(
                        routines.activeRoutine == null ||
                                routines.activeRoutine!.tasks.isEmpty
                            ? l.t('home.routinePreviewEmpty')
                            : routines.activeRoutine!.tasks[
                                    routines.currentTaskIndex %
                                        routines.activeRoutine!.tasks.length]
                                .title,
                      ),
                      trailing: TextButton(
                        onPressed: () => context.push('/routines'),
                        child: Text(l.t('home.myRoutine')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: buttonHeight,
                    ),
                    itemCount: layout.length,
                    itemBuilder: (BuildContext context, int i) {
                      final String key = layout[i];
                      final v = _catalog[key];
                      if (v == null) return const SizedBox.shrink();
                      return LargeCardButton(
                        label: l.t(v.labelKey),
                        icon: v.icon,
                        colorName: v.color,
                        minHeight: buttonHeight,
                        onTap: () => _open(key),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.avatarKey});
  final String avatarKey;

  @override
  Widget build(BuildContext context) {
    final Map<String, IconData> icons = <String, IconData>{
      'sun': Icons.wb_sunny,
      'star': Icons.star,
      'heart': Icons.favorite,
      'cat': Icons.cruelty_free,
      'bloom': Icons.local_florist,
      'rocket': Icons.rocket_launch,
    };
    return CircleAvatar(
      backgroundColor: AppColors.yellow.withValues(alpha: 0.3),
      child: Icon(icons[avatarKey] ?? Icons.wb_sunny, color: AppColors.yellow),
    );
  }
}
