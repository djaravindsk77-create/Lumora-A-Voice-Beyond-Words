import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Slim highlighted strip for a short informational line.
///
/// The always-on "Demo Mode" notice was removed from the UI on request: with
/// no text supplied the widget renders nothing, so the app never shows a demo
/// banner. Screens that genuinely need a tip strip (the Calm Space intro, for
/// example) pass their own text in.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if ((text ?? '').isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.yellow.withValues(alpha: 0.25),
      child: Row(
        children: <Widget>[
          const Icon(Icons.science, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip showing the sync status; honest labels only.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.label,
    required this.ok,
  });

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.warning.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            ok ? Icons.cloud_done : Icons.cloud_off,
            size: 14,
            color: ok ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
