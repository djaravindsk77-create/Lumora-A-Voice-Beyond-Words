import 'package:flutter/foundation.dart';

/// One step within a routine task (step-by-step task guidance).
@immutable
class TaskStep {
  const TaskStep({
    required this.id,
    required this.text,
    this.textTa,
    this.iconKey = 'check_circle',
    this.colorName = 'blue',
    this.audioPath,
  });

  final String id;
  final String text;
  final String? textTa;
  final String iconKey;
  final String colorName;

  /// Optional caregiver-recorded audio instruction.
  final String? audioPath;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'textTa': textTa,
        'iconKey': iconKey,
        'colorName': colorName,
        'audioPath': audioPath,
      };

  factory TaskStep.fromJson(Map<String, dynamic> json) => TaskStep(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        textTa: json['textTa'] as String?,
        iconKey: json['iconKey'] as String? ?? 'check_circle',
        colorName: json['colorName'] as String? ?? 'blue',
        audioPath: json['audioPath'] as String?,
      );
}

/// A task inside a visual routine. Tasks may embed ordered steps.
@immutable
class RoutineTask {
  const RoutineTask({
    required this.id,
    required this.title,
    this.titleTa,
    this.iconKey = 'task_alt',
    this.colorName = 'blue',
    this.steps = const <TaskStep>[],
    this.notifyOnComplete = false,
  });

  final String id;
  final String title;
  final String? titleTa;
  final String iconKey;
  final String colorName;
  final List<TaskStep> steps;
  final bool notifyOnComplete;

  RoutineTask copyWith({List<TaskStep>? steps}) => RoutineTask(
        id: id,
        title: title,
        titleTa: titleTa,
        iconKey: iconKey,
        colorName: colorName,
        steps: steps ?? this.steps,
        notifyOnComplete: notifyOnComplete,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'titleTa': titleTa,
        'iconKey': iconKey,
        'colorName': colorName,
        'steps': steps.map((TaskStep s) => s.toJson()).toList(),
        'notifyOnComplete': notifyOnComplete,
      };

  factory RoutineTask.fromJson(Map<String, dynamic> json) => RoutineTask(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        titleTa: json['titleTa'] as String?,
        iconKey: json['iconKey'] as String? ?? 'task_alt',
        colorName: json['colorName'] as String? ?? 'blue',
        steps: ((json['steps'] as List<dynamic>? ?? const <dynamic>[]))
            .map<TaskStep>((dynamic s) =>
                TaskStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        notifyOnComplete: json['notifyOnComplete'] as bool? ?? false,
      );
}

/// A visual routine (morning/evening/custom) with picture-based tasks.
@immutable
class Routine {
  const Routine({
    required this.id,
    required this.childId,
    required this.name,
    required this.kind,
    required this.tasks,
    required this.createdAt,
    this.repeat = 'daily',
    this.paused = false,
  });

  final String id;
  final String childId;

  /// morning | evening | custom
  final String kind;
  final String name;
  final List<RoutineTask> tasks;

  /// daily | weekdays | once
  final String repeat;
  final bool paused;
  final DateTime createdAt;

  Routine copyWith({
    String? name,
    List<RoutineTask>? tasks,
    String? repeat,
    bool? paused,
  }) =>
      Routine(
        id: id,
        childId: childId,
        name: name ?? this.name,
        kind: kind,
        tasks: tasks ?? this.tasks,
        repeat: repeat ?? this.repeat,
        paused: paused ?? this.paused,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'name': name,
        'kind': kind,
        'tasks': tasks.map((RoutineTask t) => t.toJson()).toList(),
        'repeat': repeat,
        'paused': paused,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String,
        childId: json['childId'] as String,
        name: json['name'] as String? ?? '',
        kind: json['kind'] as String? ?? 'custom',
        tasks: ((json['tasks'] as List<dynamic>? ?? const <dynamic>[]))
            .map<RoutineTask>((dynamic t) =>
                RoutineTask.fromJson(t as Map<String, dynamic>))
            .toList(),
        repeat: json['repeat'] as String? ?? 'daily',
        paused: json['paused'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// History record of a routine completion for reports.
@immutable
class RoutineCompletion {
  const RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.childId,
    required this.completedAt,
    required this.totalTasks,
    required this.completedTasks,
  });

  final String id;
  final String routineId;
  final String childId;
  final DateTime completedAt;
  final int totalTasks;
  final int completedTasks;

  double get ratio =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'routineId': routineId,
        'childId': childId,
        'completedAt': completedAt.toIso8601String(),
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
      };

  factory RoutineCompletion.fromJson(Map<String, dynamic> json) =>
      RoutineCompletion(
        id: json['id'] as String,
        routineId: json['routineId'] as String,
        childId: json['childId'] as String,
        completedAt:
            DateTime.tryParse(json['completedAt'] as String? ?? '') ??
                DateTime.now(),
        totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
        completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      );
}
