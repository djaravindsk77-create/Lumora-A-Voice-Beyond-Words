import 'package:flutter/material.dart';

import '../models/barrel.dart';
import '../repositories/lumora_repository.dart';
import 'settings_provider.dart';

/// Routine state: today's routine flow, completion tracking and history.
class RoutineProvider extends ChangeNotifier {
  RoutineProvider(this._settings);

  // Kept for parity with other providers; reminder scheduling reads
  // settings directly via NotificationService, so this may be unused today.
  // ignore: unused_field
  final SettingsProvider _settings;
  final LumoraRepository _repo = LumoraRepository.instance;

  List<Routine> _routines = <Routine>[];
  String? _activeRoutineId;
  final Set<String> _completedTaskIds = <String>{};
  int _currentTaskIndex = 0;
  int _currentStepIndex = 0;

  List<Routine> get routines => List.unmodifiable(_routines);
  Routine? get activeRoutine =>
      _routines.where((Routine r) => r.id == _activeRoutineId).firstOrNull;
  Set<String> get completedTaskIds => Set.unmodifiable(_completedTaskIds);
  int get currentTaskIndex => _currentTaskIndex;
  int get currentStepIndex => _currentStepIndex;

  double get completionRatio {
    final Routine? r = activeRoutine;
    if (r == null || r.tasks.isEmpty) return 0;
    return _completedTaskIds.length / r.tasks.length;
  }

  bool get allCompleted {
    final Routine? r = activeRoutine;
    return r != null &&
        r.tasks.isNotEmpty &&
        _completedTaskIds.length == r.tasks.length;
  }

  Future<void> load(String childId) async {
    _routines = _repo.getRoutines()
        .where((Routine r) => r.childId == childId && !r.paused)
        .toList();
    if (_routines.isNotEmpty && _activeRoutineId == null) {
      _activeRoutineId = _routines.first.id;
    }
    notifyListeners();
  }

  Future<void> selectRoutine(String routineId) async {
    _activeRoutineId = routineId;
    _completedTaskIds.clear();
    _currentTaskIndex = 0;
    _currentStepIndex = 0;
    notifyListeners();
  }

  void markTaskComplete(String taskId) {
    _completedTaskIds.add(taskId);
    final Routine? r = activeRoutine;
    if (r != null) {
      final int idx = r.tasks.indexWhere((RoutineTask t) => t.id == taskId);
      if (idx >= 0 && idx == _currentTaskIndex) {
        _currentTaskIndex = (idx + 1).clamp(0, r.tasks.length - 1);
      }
    }
    FeedbackBridge.tap();
    notifyListeners();
  }

  void toggleTaskComplete(String taskId) {
    if (_completedTaskIds.contains(taskId)) {
      _completedTaskIds.remove(taskId);
    } else {
      _completedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void nextStep() {
    final Routine? r = activeRoutine;
    if (r == null) return;
    final List<TaskStep> steps = r.tasks[_currentTaskIndex].steps;
    if (_currentStepIndex < steps.length - 1) {
      _currentStepIndex++;
    }
    notifyListeners();
  }

  void previousStep() {
    if (_currentStepIndex > 0) _currentStepIndex--;
    notifyListeners();
  }

  /// Records a completion event (once per routine selection).
  Future<void> completeRoutine(String childId) async {
    final Routine? r = activeRoutine;
    if (r == null) return;
    await _repo.saveRoutineCompletion(RoutineCompletion(
      id: _repo.local.newId(),
      routineId: r.id,
      childId: childId,
      completedAt: DateTime.now(),
      totalTasks: r.tasks.length,
      completedTasks: _completedTaskIds.length,
    ));
    FeedbackBridge.confirm();
  }

  // -- CRUD for parents ------------------------------------------------

  Future<void> saveRoutine(Routine r) async {
    await _repo.saveRoutine(r);
    _routines = _repo.getRoutines()
        .where((Routine rr) => rr.childId == r.childId)
        .toList();
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    await _repo.deleteRoutine(id);
    _routines = _routines.where((Routine r) => r.id != id).toList();
    if (_activeRoutineId == id) _activeRoutineId = _routines.firstOrNull?.id;
    notifyListeners();
  }

  Future<void> togglePause(Routine r) async {
    await _repo.saveRoutine(r.copyWith(paused: !r.paused));
    _routines = _repo.getRoutines()
        .where((Routine rr) => rr.childId == r.childId)
        .toList();
    notifyListeners();
  }
}

/// Minimal bridge so provider code stays testable without bindings.
class FeedbackBridge {
  static void Function()? _tap;
  static void Function()? _confirm;

  static void bind({void Function()? tap, void Function()? confirm}) {
    _tap = tap;
    _confirm = confirm;
  }

  static void tap() => _tap?.call();
  static void confirm() => _confirm?.call();
}
