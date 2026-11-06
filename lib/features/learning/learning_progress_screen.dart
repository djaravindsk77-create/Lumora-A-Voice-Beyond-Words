import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../providers/learning_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/barrel.dart';

/// Learning progress overview (child-facing, encouraging framing).
class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LearningProvider learning = context.watch<LearningProvider>();
    final String childId =
        context.watch<SessionProvider>().child?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l.t('learn.progress'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: l.t('learn.stars'),
                  value: '${learning.totalStars(childId)}',
                  icon: Icons.star,
                  colorName: 'yellow',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: l.t('track.daily'),
                  value: '${learning.todayCompletions(childId)}',
                  icon: Icons.done_all,
                  colorName: 'green',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.t('learn.goals'),
              style: Theme.of(context).textTheme.titleMedium),
          if (learning.goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.t('learn.noGoals'),
                  style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ...learning.goals.map(
              (String g) => Card(
                child: ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(g),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
