import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/feedback_service.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/routine.dart' show RoutineTask;
import '../../providers/routine_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/barrel.dart';

/// Visual Routine Planner for the child: picture task cards with a big
/// completion button, progress bar and a "All done!" celebration state.
class RoutinePlannerScreen extends StatefulWidget {
  const RoutinePlannerScreen({super.key});

  @override
  State<RoutinePlannerScreen> createState() => _RoutinePlannerScreenState();
}

class _RoutinePlannerScreenState extends State<RoutinePlannerScreen> {
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String childId =
          context.read<SessionProvider>().child?.id ?? '';
      context.read<RoutineProvider>().load(childId);
    });
  }

  Future<void> _completeAll() async {
    final RoutineProvider routines = context.read<RoutineProvider>();
    final String childId =
        context.read<SessionProvider>().child?.id ?? '';
    for (final task in routines.activeRoutine?.tasks ?? <RoutineTask>[]) {
      routines.markTaskComplete(task.id);
    }
    await routines.completeRoutine(childId);
    FeedbackService.confirm();
    if (mounted) setState(() => _celebrated = true);
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final RoutineProvider routines = context.watch<RoutineProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('routine.title')),
        actions: <Widget>[
          SignOutButton(),
          if (routines.routines.length > 1)
            IconButton(
              tooltip: l.t('modes.switchMode'),
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _pickRoutine(context, routines),
            ),
        ],
      ),
      body: SafeArea(
        child: routines.activeRoutine == null
            ? EmptyView(
                title: l.t('routine.noRoutines'),
                icon: Icons.checklist,
              )
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                l.t('routine.today'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                            Text(
                              '${routines.completedTaskIds.length}/${routines.activeRoutine!.tasks.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: routines.completionRatio,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 130,
                      ),
                      itemCount: routines.activeRoutine!.tasks.length,
                      itemBuilder: (BuildContext context, int i) {
                        final RoutineTask t =
                            routines.activeRoutine!.tasks[i];
                        final bool done = routines.completedTaskIds
                            .contains(t.id);
                        final Color color =
                            AppColors.fromName(t.colorName);
                        return Semantics(
                          button: true,
                          label: t.title,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              routines.toggleTaskComplete(t.id);
                              FeedbackService.tap();
                              if (routines.allCompleted &&
                                  !_celebrated) {
                                _completeAll();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: done ? 0.3 : 0.13),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.5),
                                  width: done ? 2.4 : 1.1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: <Widget>[
                                  done
                                      ? const Icon(Icons.check_circle,
                                          size: 44,
                                          color: AppColors.success)
                                      : Icon(IconCatalog.of(t.iconKey),
                                          size: 44, color: color),
                                  const SizedBox(height: 6),
                                  Text(
                                    t.title,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  if (t.steps.isNotEmpty)
                                    Text(
                                      '${t.steps.length} ${l.t('routine.steps').toLowerCase()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_celebrated)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l.t('routine.allDone'),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: AppColors.success),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _pickRoutine(BuildContext context, RoutineProvider routines) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: routines.routines
              .map(
                (r) => ListTile(
                  leading: const Icon(Icons.checklist),
                  title: Text(r.name),
                  trailing: r.id == routines.activeRoutine?.id
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    routines.selectRoutine(r.id);
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
