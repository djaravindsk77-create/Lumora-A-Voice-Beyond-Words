import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utilities/feedback_service.dart';
import '../core/utilities/icon_catalog.dart';
import '../models/barrel.dart';

/// A tappable picture card used on the AAC board.
/// Shows an icon or a custom photo, the label, and a favourite star.
class AacCardTile extends StatelessWidget {
  const AacCardTile({
    super.key,
    required this.card,
    required this.languageCode,
    required this.onTap,
    this.onToggleFavorite,
    this.compact = false,
  });

  final PictureCard card;
  final String languageCode;
  final VoidCallback onTap;

  /// When provided, shows a star toggle instead of taking the whole tile.
  final VoidCallback? onToggleFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color base = AppColors.fromName(card.colorName);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark
        ? base.withValues(alpha: 0.25)
        : base.withValues(alpha: 0.14);
    final Color border =
        isDark ? base.withValues(alpha: 0.6) : base.withValues(alpha: 0.4);
    final String label = card.label(languageCode);

    final Widget visual = card.customImagePath != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(card.customImagePath!),
              width: compact ? 34 : 56,
              height: compact ? 34 : 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(IconCatalog.of(card.iconKey),
                  size: compact ? 30 : 48, color: base),
            ),
          )
        : Icon(IconCatalog.of(card.iconKey),
            size: compact ? 30 : 48, color: base);

    final Widget content = InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        FeedbackService.tap();
        onTap();
      },
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            visual,
            SizedBox(height: compact ? 4 : 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: compact
                  ? Theme.of(context).textTheme.labelMedium
                  : Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      label: label,
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: content,
          ),
          if (onToggleFavorite != null)
            Positioned(
              top: 2,
              right: 2,
              child: SizedBox(
                width: 34,
                height: 34,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  tooltip: 'Favorite',
                  icon: Icon(
                    card.isFavorite ? Icons.star : Icons.star_border,
                    color: card.isFavorite ? AppColors.yellow : null,
                  ),
                  onPressed: onToggleFavorite,
                ),
              ),
            ),
          if (card.aiGenerated)
            Positioned(
              top: 2,
              left: 2,
              child: Icon(Icons.auto_awesome,
                  size: 14, color: Theme.of(context).colorScheme.secondary),
            ),
        ],
      ),
    );
  }

  /// Central icon-key -> IconData lookup, delegating to [IconCatalog].
  static IconData iconFor(String key) => IconCatalog.of(key);
}
