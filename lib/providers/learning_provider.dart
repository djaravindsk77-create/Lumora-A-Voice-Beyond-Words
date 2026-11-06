import 'package:flutter/material.dart';

import '../features/learning/learning_catalog.dart';
import '../models/barrel.dart';
import '../repositories/lumora_repository.dart';
import '../services/ai/suggestion_engine.dart';
import 'settings_provider.dart';

/// Learning state: catalog, in-memory progress, adaptive recommendations.
class LearningProvider extends ChangeNotifier {
  LearningProvider(this._settings);

  final SettingsProvider _settings;
  final LumoraRepository _repo = LumoraRepository.instance;

  final List<LearningActivity> _catalog =
      List<LearningActivity>.from(LearningCatalog.activities);
  List<LearningProgress> _progress = <LearningProgress>[];
  List<String> _goals = <String>[];
  LearningLevel _selectedLevel = LearningLevel.beginner;

  List<LearningActivity> get catalog => List.unmodifiable(_catalog);
  List<LearningProgress> get progress => List.unmodifiable(_progress);
  List<String> get goals => List.unmodifiable(_goals);
  LearningLevel get selectedLevel => _selectedLevel;

  Future<void> load(String childId) async {
    // Progress is persisted per child in Hive via the repository.
    _progress = _repo
        .getLearningProgress()
        .where((LearningProgress p) => p.childId == childId)
        .toList();
    _progressById[childId] = List<LearningProgress>.from(_progress);
    _goals = _settings.settings.lastChildId.isEmpty
        ? <String>[]
        : _loadGoals(childId);
    _selectedLevel = _levelFromChild(childId);
    notifyListeners();
  }

  LearningLevel _levelFromChild(String childId) {
    final ChildProfile? child = _repo.getChild(childId);
    switch (child?.learningLevel) {
      case 'intermediate':
        return LearningLevel.intermediate;
      case 'advanced':
        return LearningLevel.advanced;
      default:
        return LearningLevel.beginner;
    }
  }

  final Map<String, List<LearningProgress>> _progressById =
      <String, List<LearningProgress>>{};

  List<String> _loadGoals(String childId) => _goalsByChild.putIfAbsent(
        childId,
        () => <String>[],
      );

  final Map<String, List<String>> _goalsByChild = <String, List<String>>{};

  void setLevel(LearningLevel level) {
    _selectedLevel = level;
    notifyListeners();
  }

  Future<void> recordResult({
    required String childId,
    required LearningActivity activity,
    required int correct,
    required int total,
    required int durationSeconds,
  }) async {
    final int stars = total == 0 ? 0 : ((correct / total) * 3).round();
    final LearningProgress p = LearningProgress(
      id: _repo.local.newId(),
      childId: childId,
      activityId: activity.id,
      level: _selectedLevel.name,
      completedAt: DateTime.now(),
      correctCount: correct,
      totalCount: total,
      durationSeconds: durationSeconds,
      starsEarned: stars,
    );
    // Persist immediately so progress survives restarts.
    await _repo.saveLearningProgress(p);
    final List<LearningProgress> list =
        _progressById.putIfAbsent(childId, () => <LearningProgress>[]);
    list.add(p);
    _progress = list;
    notifyListeners();
  }

  /// Rule-based adaptive recommendations.
  List<LearningActivity> recommendations(String childId, {int count = 3}) {
    final ChildProfile? child = _repo.getChild(childId);
    return SuggestionEngine.instance.recommendActivities(
      catalog: _catalog,
      progress: _progressById[childId] ?? _progress,
      child: child ??
          ChildProfile(
              id: childId,
              name: 'Child',
              favoriteActivityIds: const <String>[]),
      count: count,
    );
  }

  int totalStars(String childId) =>
      (_progressById[childId] ?? _progress)
          .fold(0, (int sum, LearningProgress p) => sum + p.starsEarned);

  /// Mean accuracy (0..1) over all recorded sessions for the child.
  double averageAccuracy(String childId) {
    final List<LearningProgress> list =
        _progressById[childId] ?? _progress;
    if (list.isEmpty) return 0;
    final int correct =
        list.fold(0, (int s, LearningProgress p) => s + p.correctCount);
    final int total =
        list.fold(0, (int s, LearningProgress p) => s + p.totalCount);
    return total == 0 ? 0 : correct / total;
  }

  int todayCompletions(String childId) =>
      (_progressById[childId] ?? _progress)
          .where((LearningProgress p) =>
              DateTime.now().difference(p.completedAt).inDays == 0)
          .length;

  void addGoal(String childId, String goal) {
    if (goal.trim().isEmpty) return;
    _goalsByChild.putIfAbsent(childId, () => <String>[]).add(goal.trim());
    _goals = _goalsByChild[childId]!;
    notifyListeners();
  }

  void removeGoal(String childId, String goal) {
    _goalsByChild[childId]?.remove(goal);
    _goals = _goalsByChild[childId] ?? <String>[];
    notifyListeners();
  }
}
