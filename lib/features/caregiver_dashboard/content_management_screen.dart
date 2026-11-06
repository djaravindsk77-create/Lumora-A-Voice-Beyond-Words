import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/barrel.dart';
import '../../widgets/barrel.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';

/// Content Management for parents: picture cards (add/edit/delete/hide/
/// favourite, photo upload, translations), categories and phrases.
class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final List<PictureCategory> categories =
        repo.getCategories(includeHidden: true);
    final List<PictureCard> cards = repo.getAllCards(includeHidden: true);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.t('content.title')),
          bottom: TabBar(
            tabs: <Tab>[
              Tab(text: l.t('content.cards')),
              Tab(text: l.t('content.categories')),
              Tab(text: l.t('content.phrases')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'add-content',
          onPressed: () => _addCard(context),
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: <Widget>[
            // ---- Cards tab ----
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cards.length,
              itemBuilder: (BuildContext context, int i) {
                final PictureCard c = cards[i];
                return ListTile(
                  leading: c.customImagePath != null
                      ? CircleAvatar(
                          backgroundImage: FileImage(File(c.customImagePath!)))
                      : CircleAvatar(
                          child: Icon(IconCatalog.of(c.iconKey),
                              size: 20, color: AppColors.fromName(c.colorName)),
                        ),
                  title: Text(
                      '${c.labelEn}${c.isHidden ? '  (${l.t('common.hide')}d)' : ''}'),
                  subtitle: Text(c.labelTa ?? '-'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String action) async {
                      switch (action) {
                        case 'edit':
                          await _addCard(context, existing: c);
                          break;
                        case 'fav':
                          await repo.saveCard(
                              c.copyWith(isFavorite: !c.isFavorite));
                          break;
                        case 'hide':
                          await repo.saveCard(
                              c.copyWith(isHidden: !c.isHidden));
                          break;
                        case 'delete':
                          await repo.deleteCard(c.id);
                          break;
                      }
                      if (context.mounted) setState(() {});
                    },
                    itemBuilder: (BuildContext ctx) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem<String>(
                          value: 'fav', child: Text('Toggle favourite')),
                      const PopupMenuItem<String>(
                          value: 'hide', child: Text('Toggle hide')),
                      const PopupMenuItem<String>(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),
            // ---- Categories tab ----
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int i) {
                final PictureCategory c = categories[i];
                return ListTile(
                  leading: Icon(IconCatalog.of(c.iconKey),
                      color: AppColors.fromName(c.colorName)),
                  title: Text(c.nameEn),
                  subtitle: Text(c.nameTa ?? '-'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await repo.deleteCategory(c.id);
                      if (context.mounted) setState(() {});
                    },
                  ),
                );
              },
            ),
            // ---- Phrases tab ----
            _PhrasesTab(onChanged: () => setState(() {})),
          ],
        ),
      ),
    );
  }

  Future<void> _addCard(BuildContext context, {PictureCard? existing}) async {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final String childLang =
        context.read<SessionProvider>().child?.languageCode ?? 'en';

    final TextEditingController en =
        TextEditingController(text: existing?.labelEn ?? '');
    final TextEditingController ta =
        TextEditingController(text: existing?.labelTa ?? '');
    String categoryId = existing?.categoryId ??
        (repo.getCategories().isNotEmpty
            ? repo.getCategories().first.id
            : 'cat-food');
    String iconKey = existing?.iconKey ?? 'star';
    String colorName = existing?.colorName ?? 'blue';
    String? photoPath = existing?.customImagePath;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, void Function(void Function()) setDialog) =>
            AlertDialog(
          title: Text(existing == null
              ? l.t('content.addCard')
              : l.t('common.edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: en,
                  decoration:
                      InputDecoration(labelText: l.t('aac.cardLabel')),
                ),
                TextField(
                  controller: ta,
                  decoration:
                      InputDecoration(labelText: l.t('aac.cardLabelTa')),
                ),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: InputDecoration(
                      labelText: l.t('content.categories')),
                  items: repo
                      .getCategories(includeHidden: true)
                      .map((PictureCategory c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(c.name(childLang)),
                          ))
                      .toList(),
                  onChanged: (String? v) =>
                      setDialog(() => categoryId = v ?? categoryId),
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: <Widget>[
                    for (final String key in IconCatalog.table.keys.take(18))
                      GestureDetector(
                        onTap: () => setDialog(() => iconKey = key),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: iconKey == key
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(IconCatalog.of(key), size: 20),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    TextButton.icon(
                      icon: const Icon(Icons.photo),
                      label: Text(l.t('aac.customPhoto')),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        try {
                          final XFile? img = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70);
                          if (img != null) {
                            setDialog(() => photoPath = img.path);
                          }
                        } on Exception {
                          // Picker unavailable - keep icon-based card.
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
          SignOutButton(),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.t('common.save')),
            ),
          ],
        ),
      ),
    );

    if (ok != true || en.text.trim().isEmpty) return;
    final PictureCard card = PictureCard(
      id: existing?.id ?? const Uuid().v4(),
      categoryId: categoryId,
      labelEn: en.text.trim(),
      labelTa: ta.text.trim().isEmpty ? null : ta.text.trim(),
      iconKey: iconKey,
      colorName: colorName,
      customImagePath: photoPath,
      isCustom: existing?.isCustom ?? true,
      isFavorite: existing?.isFavorite ?? false,
      isHidden: existing?.isHidden ?? false,
    );
    await repo.saveCard(card);
    if (context.mounted) setState(() {});
  }
}

class _PhrasesTab extends StatelessWidget {
  const _PhrasesTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final LumoraRepository repo = LumoraRepository.instance;
    final List<SavedPhrase> phrases = repo.getPhrases();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(l.t('content.createPhrase'),
              style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: phrases.length,
            itemBuilder: (BuildContext context, int i) {
              final SavedPhrase p = phrases[i];
              return ListTile(
                leading: Icon(
                  p.isFavorite ? Icons.star : Icons.notes,
                  color: p.isFavorite ? AppColors.yellow : null,
                ),
                title: Text(p.text),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await repo.deletePhrase(p.id);
                    onChanged();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
