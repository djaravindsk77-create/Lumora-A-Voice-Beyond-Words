import 'package:flutter/foundation.dart';

/// Difficulty levels for learning activities.
enum LearningLevel { beginner, intermediate, advanced }

/// Categories of learning activities.
enum ActivityCategory {
  colors,
  shapes,
  numbers,
  alphabets,
  animals,
  fruits,
  vegetables,
  vehicles,
  bodyParts,
  household,
  communityHelpers,
  basicWords,
  matching,
  sorting,
  memory,
  pictureId,
  puzzles,
  lifeSkills,
}

extension ActivityCategoryX on ActivityCategory {
  String get id {
    switch (this) {
      case ActivityCategory.colors:
        return 'colors';
      case ActivityCategory.shapes:
        return 'shapes';
      case ActivityCategory.numbers:
        return 'numbers';
      case ActivityCategory.alphabets:
        return 'alphabets';
      case ActivityCategory.animals:
        return 'animals';
      case ActivityCategory.fruits:
        return 'fruits';
      case ActivityCategory.vegetables:
        return 'vegetables';
      case ActivityCategory.vehicles:
        return 'vehicles';
      case ActivityCategory.bodyParts:
        return 'bodyParts';
      case ActivityCategory.household:
        return 'household';
      case ActivityCategory.communityHelpers:
        return 'communityHelpers';
      case ActivityCategory.basicWords:
        return 'basicWords';
      case ActivityCategory.matching:
        return 'matching';
      case ActivityCategory.sorting:
        return 'sorting';
      case ActivityCategory.memory:
        return 'memory';
      case ActivityCategory.pictureId:
        return 'pictureId';
      case ActivityCategory.puzzles:
        return 'puzzles';
      case ActivityCategory.lifeSkills:
        return 'lifeSkills';
    }
  }

  String get l10nKey => 'learn.$id';
}

ActivityCategory activityCategoryFromId(String id) {
  for (final ActivityCategory c in ActivityCategory.values) {
    if (c.id == id) return c;
  }
  return ActivityCategory.colors;
}

/// One generated question for quiz-style activities.
@immutable
class ActivityQuestion {
  const ActivityQuestion({
    required this.promptKey,
    required this.promptParams,
    required this.answer,
    required this.options,
    this.speakText,
  });

  final String promptKey;
  final Map<String, String> promptParams;
  final String answer;
  final List<String> options;

  /// Text to speak aloud as the instruction.
  final String? speakText;
}

/// A learning activity definition. Question banks for quiz activities are
/// provided by [LearningCatalog] / the rule-based recommendation engine.
@immutable
class LearningActivity {
  const LearningActivity({
    required this.id,
    required this.category,
    required this.titleKey,
    required this.iconKey,
    required this.colorName,
    this.descriptionKey = 'learn.chooseAnswer',
    this.levels = const <LearningLevel>[
      LearningLevel.beginner,
      LearningLevel.intermediate,
      LearningLevel.advanced,
    ],
    this.isCustom = false,
    this.enabled = true,
  });

  final String id;
  final ActivityCategory category;
  final String titleKey;

  /// Localization key of the instruction shown before playing.
  final String descriptionKey;
  final String iconKey;
  final String colorName;
  final List<LearningLevel> levels;

  /// True for parent-created activities.
  final bool isCustom;
  final bool enabled;
}

/// Recorded progress for one activity.
@immutable
class LearningProgress {
  const LearningProgress({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.level,
    required this.completedAt,
    this.correctCount = 0,
    this.totalCount = 0,
    this.durationSeconds = 0,
    this.starsEarned = 0,
  });

  final String id;
  final String childId;
  final String activityId;
  final String level;
  final DateTime completedAt;
  final int correctCount;
  final int totalCount;
  final int durationSeconds;
  final int starsEarned;

  double get accuracy =>
      totalCount == 0 ? 0 : correctCount / totalCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'activityId': activityId,
        'level': level,
        'completedAt': completedAt.toIso8601String(),
        'correctCount': correctCount,
        'totalCount': totalCount,
        'durationSeconds': durationSeconds,
        'starsEarned': starsEarned,
      };

  factory LearningProgress.fromJson(Map<String, dynamic> json) =>
      LearningProgress(
        id: json['id'] as String,
        childId: json['childId'] as String,
        activityId: json['activityId'] as String,
        level: json['level'] as String? ?? 'beginner',
        completedAt:
            DateTime.tryParse(json['completedAt'] as String? ?? '') ??
                DateTime.now(),
        correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        starsEarned: (json['starsEarned'] as num?)?.toInt() ?? 0,
      );
}
