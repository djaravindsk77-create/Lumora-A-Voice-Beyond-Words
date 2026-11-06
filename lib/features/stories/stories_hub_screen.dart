import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../data/demo/demo_data.dart';
import '../../models/story.dart';
import '../../widgets/barrel.dart';

/// Stories hub listing the ten built-in social stories plus any custom
/// stories the caregiver created. All content works offline.
class StoriesHubScreen extends StatelessWidget {
  const StoriesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final String lang =
        'en'; // resolved per story below (uses titleTa when present)
    final List<Story> stories = DemoData.stories;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('story.title')),
        actions: const <Widget>[SignOutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(l.t('story.social'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...stories.map(
            (Story s) {
              final Color color = AppColors.fromName(s.colorName);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.18),
                    child: Icon(IconCatalog.of(s.iconKey), color: color),
                  ),
                  title: Text(lang == 'ta'
                      ? (s.titleTa ?? s.title)
                      : s.title),
                  subtitle: Text(
                      '${s.pages.length} ${l.t('story.page')}s · ${l.t('story.narration')} ✓'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/stories/${s.id}'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            l.t('story.customNote'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
