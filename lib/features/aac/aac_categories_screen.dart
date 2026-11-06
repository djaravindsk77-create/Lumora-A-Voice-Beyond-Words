import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/barrel.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/sign_out_button.dart';
import '../../widgets/barrel.dart';

/// AAC Categories screen: grid of categories plus Favorites.
class AacCategoriesScreen extends StatelessWidget {
  const AacCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final SessionProvider session = context.watch<SessionProvider>();
    final String lang = session.child?.languageCode ?? 'en';
    final List<PictureCategory> categories =
        LumoraRepository.instance.getCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('aac.title')),
        actions: <Widget>[
          SignOutButton(),
          IconButton(
            tooltip: l.t('aac.searchCards'),
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/aac/search'),
          ),
          IconButton(
            tooltip: l.t('aac.favoritesCat'),
            icon: const Icon(Icons.star),
            onPressed: () => context.push('/aac/favorites'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SentenceBarEntry(),
            Expanded(
              child: categories.isEmpty
                  ? EmptyView(
                      title: l.t('aac.noCards'),
                      subtitle: l.t('aac.boardEmpty'),
                      icon: Icons.grid_view,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (BuildContext context, int i) {
                        final PictureCategory c = categories[i];
                        final Color color = AppColors.fromName(c.colorName);
                        return Semantics(
                          button: true,
                          label: c.name(lang),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => context.push('/aac/board/${c.id}'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(IconCatalog.of(c.iconKey),
                                      size: 44, color: color),
                                  const SizedBox(height: 6),
                                  Text(
                                    c.name(lang),
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact live sentence strip shown above AAC screens; opens the builder.
class SentenceBarEntry extends StatelessWidget {
  const SentenceBarEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: ListTile(
          dense: true,
          leading: const Icon(Icons.format_align_left),
          title: Text(context.l10n.t('aac.sentence')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/sentence-builder'),
        ),
      ),
    );
  }
}
