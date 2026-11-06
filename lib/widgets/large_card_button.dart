import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utilities/feedback_service.dart';

/// A big, rounded, colourful card button used across Child Mode.
/// Minimum height is 96 logical pixels (large touch target) and it supports
/// screen-reader labels and gentle feedback.
class LargeCardButton extends StatelessWidget {
  const LargeCardButton({
    super.key,
    required this.label,
    required this.icon,
    required this.colorName,
    required this.onTap,
    this.subtitle,
    this.minHeight = 96,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String colorName;
  final VoidCallback onTap;
  final String? subtitle;
  final double minHeight;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color base = AppColors.fromName(colorName);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg =
        isDark ? base.withValues(alpha: 0.25) : base.withValues(alpha: 0.16);
    final Color border =
        isDark ? base.withValues(alpha: 0.6) : base.withValues(alpha: 0.45);
    final TextStyle? titleStyle = Theme.of(context).textTheme.titleMedium;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            FeedbackService.tap();
            onTap();
          },
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border, width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 40, color: cs.onSurface),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (badge != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
