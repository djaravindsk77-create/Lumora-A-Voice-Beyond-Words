import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utilities/icon_catalog.dart';
import '../../models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../services/speech/tts_service.dart';
import '../../widgets/barrel.dart';

/// Step-by-Step Task Guidance: walks through the steps of one routine task
/// with pictures, short instructions, optional audio and a progress bar.
class TaskGuidanceScreen extends StatefulWidget {
  const TaskGuidanceScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskGuidanceScreen> createState() => _TaskGuidanceScreenState();
}

class _TaskGuidanceScreenState extends State<TaskGuidanceScreen> {
  RoutineTask? _task;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RoutineProvider routines = context.read<RoutineProvider>();
      for (final Routine r in routines.routines) {
        for (final RoutineTask t in r.tasks) {
          if (t.id == widget.taskId) {
            setState(() => _task = t);
            return;
          }
        }
      }
      // Fallback: the brushing-teeth sample steps so the screen is never
      // empty even when opened without a selected task.
      setState(() {
        _task = const RoutineTask(
          id: 'fallback',
          title: 'Brushing teeth',
          iconKey: 'brush',
          steps: <TaskStep>[
            TaskStep(id: '1', text: 'Take the toothbrush', iconKey: 'brush'),
            TaskStep(id: '2', text: 'Apply toothpaste', iconKey: 'water_drop'),
            TaskStep(id: '3', text: 'Brush teeth', iconKey: 'sentiment_satisfied'),
            TaskStep(id: '4', text: 'Rinse mouth', iconKey: 'wash'),
            TaskStep(id: '5', text: 'Put the toothbrush away', iconKey: 'task_alt'),
          ],
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final RoutineTask? task = _task;

    if (task == null) return const Scaffold(body: LoadingView());

    final TaskStep step = task.steps[_step];
    final Color color = AppColors.fromName(step.colorName);

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Text(
                l.t('routine.stepOf',
                    <String, String>{
                      'current': '${_step + 1}',
                      'total': '${task.steps.length}',
                    }),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_step + 1) / task.steps.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const Spacer(),
              Icon(IconCatalog.of(step.iconKey), size: 96, color: color),
              const SizedBox(height: 20),
              Text(
                step.text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              IconButton(
                tooltip: l.t('story.narration'),
                icon: const Icon(Icons.volume_up, size: 36),
                onPressed: () => TtsService.instance.speak(step.text),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l.t('routine.prevStep')),
                    onPressed: _step == 0
                        ? null
                        : () => setState(() => _step--),
                  ),
                  FilledButton.icon(
                    icon: Icon(
                        _step == task.steps.length - 1
                            ? Icons.check
                            : Icons.arrow_forward),
                    label: Text(_step == task.steps.length - 1
                        ? l.t('common.done')
                        : l.t('routine.nextStep')),
                    onPressed: () {
                      if (_step == task.steps.length - 1) {
                        Navigator.of(context).maybePop();
                        return;
                      }
                      setState(() => _step++);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
