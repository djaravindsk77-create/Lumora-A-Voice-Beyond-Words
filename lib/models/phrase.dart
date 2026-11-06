import 'package:flutter/foundation.dart';

/// A phrase saved in the Voice Communication module (also used for saved
/// phrases in AAC/Needs). Frequencies feed the tracker and reports.
@immutable
class SavedPhrase {
  const SavedPhrase({
    required this.id,
    required this.childId,
    required this.text,
    this.languageCode = 'en',
    this.isFavorite = false,
    this.usageCount = 0,
    this.lastUsedAt,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String text;
  final String languageCode;
  final bool isFavorite;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;

  SavedPhrase copyWith({
    String? text,
    bool? isFavorite,
    int? usageCount,
    DateTime? lastUsedAt,
  }) =>
      SavedPhrase(
        id: id,
        childId: childId,
        text: text ?? this.text,
        languageCode: languageCode,
        isFavorite: isFavorite ?? this.isFavorite,
        usageCount: usageCount ?? this.usageCount,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'text': text,
        'languageCode': languageCode,
        'isFavorite': isFavorite,
        'usageCount': usageCount,
        'lastUsedAt': lastUsedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory SavedPhrase.fromJson(Map<String, dynamic> json) => SavedPhrase(
        id: json['id'] as String,
        childId: json['childId'] as String,
        text: json['text'] as String,
        languageCode: json['languageCode'] as String? ?? 'en',
        isFavorite: json['isFavorite'] as bool? ?? false,
        usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
        lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}

/// One entry of sentence history (sentence builder / AAC sentence bar).
@immutable
class SentenceHistory {
  const SentenceHistory({
    required this.id,
    required this.childId,
    required this.words,
    required this.spokenText,
    this.createdAt,
    this.isFavorite = false,
    this.usageCount = 0,
  });

  final String id;
  final String childId;
  final List<String> words;
  final String spokenText;
  final DateTime? createdAt;
  final bool isFavorite;
  final int usageCount;

  SentenceHistory copyWith({
    bool? isFavorite,
    int? usageCount,
  }) =>
      SentenceHistory(
        id: id,
        childId: childId,
        words: words,
        spokenText: spokenText,
        createdAt: createdAt,
        isFavorite: isFavorite ?? this.isFavorite,
        usageCount: usageCount ?? this.usageCount,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'words': words,
        'spokenText': spokenText,
        'createdAt': createdAt?.toIso8601String(),
        'isFavorite': isFavorite,
        'usageCount': usageCount,
      };

  factory SentenceHistory.fromJson(Map<String, dynamic> json) =>
      SentenceHistory(
        id: json['id'] as String,
        childId: json['childId'] as String,
        words: (json['words'] as List<dynamic>? ?? const []).cast<String>(),
        spokenText: json['spokenText'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        isFavorite: json['isFavorite'] as bool? ?? false,
        usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      );
}
