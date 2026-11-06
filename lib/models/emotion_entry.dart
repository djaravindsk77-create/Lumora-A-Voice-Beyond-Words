import 'package:flutter/foundation.dart';

/// A recorded emotion selection from the Feelings module.
///
/// Lumora never interprets or diagnoses emotions - entries are exactly what
/// the child selected, stored for supportive review by caregivers.
@immutable
class EmotionEntry {
  const EmotionEntry({
    required this.id,
    required this.childId,
    required this.emotionId,
    this.comfortChoiceId,
    this.note,
    this.notifiedCaregiver = false,
    this.createdAt,
  });

  final String id;
  final String childId;

  /// e.g. 'happy', 'sad', 'angry' ... (see EmotionCatalog).
  final String emotionId;

  /// e.g. 'hug', 'quiet', 'music', 'talk', 'break'.
  final String? comfortChoiceId;
  final String? note;

  /// Whether caregivers were notified (only for parent-enabled emotions).
  final bool notifiedCaregiver;
  final DateTime? createdAt;

  EmotionEntry copyWith({bool? notifiedCaregiver, String? comfortChoiceId}) =>
      EmotionEntry(
        id: id,
        childId: childId,
        emotionId: emotionId,
        comfortChoiceId: comfortChoiceId ?? this.comfortChoiceId,
        note: note,
        notifiedCaregiver: notifiedCaregiver ?? this.notifiedCaregiver,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'emotionId': emotionId,
        'comfortChoiceId': comfortChoiceId,
        'note': note,
        'notifiedCaregiver': notifiedCaregiver,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory EmotionEntry.fromJson(Map<String, dynamic> json) => EmotionEntry(
        id: json['id'] as String,
        childId: json['childId'] as String,
        emotionId: json['emotionId'] as String,
        comfortChoiceId: json['comfortChoiceId'] as String?,
        note: json['note'] as String?,
        notifiedCaregiver: json['notifiedCaregiver'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

/// Catalog of emotions the child can pick, with icon/colour keys.
class EmotionCatalog {
  EmotionCatalog._();

  static const List<String> ids = <String>[
    'happy',
    'sad',
    'angry',
    'scared',
    'confused',
    'excited',
    'tired',
    'worried',
    'calm',
    'uncomfortable',
    'sick',
    'pain',
  ];

  static String l10nKey(String id) => 'emo.$id';

  static String iconKey(String id) {
    switch (id) {
      case 'happy':
        return 'sentiment_very_satisfied';
      case 'sad':
        return 'sentiment_dissatisfied';
      case 'angry':
        return 'mood_bad';
      case 'scared':
        return 'sentiment_extremely_dissatisfied';
      case 'confused':
        return 'psychology_alt';
      case 'excited':
        return 'celebration';
      case 'tired':
        return 'bedtime';
      case 'worried':
        return 'sentiment_stressed';
      case 'calm':
        return 'self_improvement';
      case 'uncomfortable':
        return 'sentiment_neutral';
      case 'sick':
        return 'sick';
      case 'pain':
        return 'healing';
    }
    return 'sentiment_neutral';
  }

  static String colorName(String id) {
    switch (id) {
      case 'happy':
      case 'excited':
        return 'yellow';
      case 'sad':
        return 'blue';
      case 'angry':
        return 'red';
      case 'scared':
      case 'worried':
        return 'purple';
      case 'confused':
        return 'gray';
      case 'tired':
        return 'purple';
      case 'calm':
        return 'teal';
      case 'uncomfortable':
        return 'orange';
      case 'sick':
      case 'pain':
        return 'red';
    }
    return 'blue';
  }

  /// Emotions that positively support comfort flows.
  static const List<String> comfortChoiceIds = <String>[
    'hug',
    'quiet',
    'music',
    'talk',
    'break',
  ];
}
