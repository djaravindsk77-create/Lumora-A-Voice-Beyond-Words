import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/learning_activity.dart';
import '../../providers/learning_provider.dart';
import '../../providers/session_provider.dart';

/// Learn & Play hub: activity grid, difficulty selector and rule-based
/// personalized recommendations.
class LearnPlayScreen extends StatefulWidget {
  const LearnPlayScreen({super.key});

  @override
  State<LearnPlayScreen> createState() => _LearnPlayScreenState();
}

class _LearnPlayScreenState extends State<LearnPlayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String childId =
          context.read<SessionProvider>().child?.id ?? '';
      if (childId.isNotEmpty) {
        context.read<LearningProvider>().load(childId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LearningProvider learning = context.watch<LearningProvider>();
    final SessionProvider session = context.watch<SessionProvider>();
    final String childId = session.child?.id ?? '';
    final List<LearningActivity> recommended =
        learning.recommendations(childId);

    return Scaffold(
      appBar: AppBar(title: Text(l.t('learn.title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.t('learn.levels'),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<LearningLevel>(
                      segments: <ButtonSegment<LearningLevel>>[
                        ButtonSegment<LearningLevel>(
                            value: LearningLevel.beginner,
                            label: Text(l.t('learn.beginner'))),
                        ButtonSegment<LearningLevel>(
                            value: LearningLevel.intermediate,
                            label: Text(l.t('learn.intermediate'))),
                        ButtonSegment<LearningLevel>(
                            value: LearningLevel.advanced,
                            label: Text(l.t('learn.advanced'))),
                      ],
                      selected: <LearningLevel>{learning.selectedLevel},
                      onSelectionChanged: (Set<LearningLevel> s) =>
                          learning.setLevel(s.first),
                    ),
                    const SizedBox(height: 6),
                    Text(l.t('learn.parentControls'),
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (recommended.isNotEmpty) ...<Widget>[
              Text(l.t('learn.recommended'),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.length,
                  itemBuilder: (BuildContext context, int i) {
                    final LearningActivity a = recommended[i];
                    return _ActivityTile(
                        activity: a, onTap: () => _open(a));
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(l.t('learn.title'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 120,
              ),
              itemCount: learning.catalog.length,
              itemBuilder: (BuildContext context, int i) {
                final LearningActivity a = learning.catalog[i];
                return _ActivityTile(activity: a, onTap: () => _open(a));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _open(LearningActivity a) {
    if (a.category == ActivityCategory.memory) {
      context.push('/learn/activity/${a.id}?mode=memory');
    } else if (a.category == ActivityCategory.matching) {
      context.push('/learn/activity/${a.id}?mode=matching');
    } else {
      context.push('/learn/activity/${a.id}?mode=quiz');
    }
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.onTap});

  final LearningActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.fromName(activity.colorName);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(IconCatalog.of(activity.iconKey),
                  size: 38, color: color),
              const SizedBox(height: 6),
              Text(
                context.l10n.t(activity.titleKey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
