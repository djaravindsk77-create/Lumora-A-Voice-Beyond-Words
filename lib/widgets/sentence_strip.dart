import 'package:flutter/material.dart';

import '../core/utilities/icon_catalog.dart';
import '../models/barrel.dart';

/// Horizontal strip showing the sentence being built from picture cards.
/// Supports tap-to-remove on each word plus clear/save/speak actions.
class SentenceStrip extends StatelessWidget {
  const SentenceStrip({
    super.key,
    required this.words,
    required this.languageCode,
    required this.onRemoveAt,
    required this.onClear,
    required this.onSpeak,
    this.onSave,
    this.emptyLabel = 'My sentence',
  });

  final List<PictureCard> words;
  final String languageCode;
  final void Function(int index) onRemoveAt;
  final VoidCallback onClear;
  final VoidCallback onSpeak;
  final VoidCallback? onSave;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  emptyLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.delete_sweep),
                onPressed: words.isEmpty ? null : onClear,
              ),
              if (onSave != null)
                IconButton(
                  tooltip: 'Save',
                  icon: const Icon(Icons.bookmark_add),
                  onPressed: words.isEmpty ? null : onSave,
                ),
              IconButton(
                tooltip: 'Speak',
                icon: const Icon(Icons.volume_up),
                onPressed: words.isEmpty ? null : onSpeak,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 64,
            child: words.isEmpty
                ? Center(
                    child: Text(
                      'Tap pictures to build a sentence',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: words.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final PictureCard card = words[index];
                      return Semantics(
                        button: true,
                        label: 'Remove ${card.label(languageCode)}',
                        child: InputChip(
                          avatar: Icon(
                            IconCatalog.of(card.iconKey),
                            size: 18,
                          ),
                          label: Text(card.label(languageCode)),
                          onDeleted: () => onRemoveAt(index),
                          onPressed: () => onRemoveAt(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
