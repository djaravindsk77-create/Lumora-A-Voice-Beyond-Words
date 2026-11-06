import 'package:flutter/foundation.dart';

/// One page of an interactive story.
@immutable
class StoryPage {
  const StoryPage({
    required this.id,
    required this.text,
    this.textTa,
    this.iconKey = 'auto_stories',
    this.colorName = 'blue',
    this.choices = const <StoryChoice>[],
    this.narrationAudioPath,
  });

  final String id;
  final String text;
  final String? textTa;
  final String iconKey;
  final String colorName;

  /// Optional choice-based interaction; tapping a choice advances to a page.
  final List<StoryChoice> choices;

  /// Caregiver-recorded narration (local file path).
  final String? narrationAudioPath;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'textTa': textTa,
        'iconKey': iconKey,
        'colorName': colorName,
        'choices': choices.map((StoryChoice c) => c.toJson()).toList(),
        'narrationAudioPath': narrationAudioPath,
      };

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        textTa: json['textTa'] as String?,
        iconKey: json['iconKey'] as String? ?? 'auto_stories',
        colorName: json['colorName'] as String? ?? 'blue',
        choices: ((json['choices'] as List<dynamic>? ?? const <dynamic>[]))
            .map<StoryChoice>((dynamic c) =>
                StoryChoice.fromJson(c as Map<String, dynamic>))
            .toList(),
        narrationAudioPath: json['narrationAudioPath'] as String?,
      );
}

/// A choice the child can make on a page.
@immutable
class StoryChoice {
  const StoryChoice({
    required this.id,
    required this.text,
    required this.nextPageId,
  });

  final String id;
  final String text;
  final String nextPageId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'nextPageId': nextPageId,
      };

  factory StoryChoice.fromJson(Map<String, dynamic> json) => StoryChoice(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        nextPageId: json['nextPageId'] as String? ?? '',
      );
}

/// A story (interactive or social).
@immutable
class Story {
  const Story({
    required this.id,
    required this.title,
    this.titleTa,
    required this.pages,
    required this.createdAt,
    this.iconKey = 'auto_stories',
    this.colorName = 'blue',
    this.isSocial = true,
    this.isFavorite = false,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String? titleTa;
  final List<StoryPage> pages;
  final DateTime createdAt;
  final String iconKey;
  final String colorName;
  final bool isSocial;
  final bool isFavorite;

  /// True for caregiver-created stories.
  final bool isCustom;

  Story copyWith({
    List<StoryPage>? pages,
    bool? isFavorite,
    String? narrationForPage,
  }) =>
      Story(
        id: id,
        title: title,
        titleTa: titleTa,
        pages: pages ?? this.pages,
        createdAt: createdAt,
        iconKey: iconKey,
        colorName: colorName,
        isSocial: isSocial,
        isFavorite: isFavorite ?? this.isFavorite,
        isCustom: isCustom,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'titleTa': titleTa,
        'pages': pages.map((StoryPage p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'iconKey': iconKey,
        'colorName': colorName,
        'isSocial': isSocial,
        'isFavorite': isFavorite,
        'isCustom': isCustom,
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        titleTa: json['titleTa'] as String?,
        pages: ((json['pages'] as List<dynamic>? ?? const <dynamic>[]))
            .map<StoryPage>((dynamic p) =>
                StoryPage.fromJson(p as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        iconKey: json['iconKey'] as String? ?? 'auto_stories',
        colorName: json['colorName'] as String? ?? 'blue',
        isSocial: json['isSocial'] as bool? ?? true,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isCustom: json['isCustom'] as bool? ?? false,
      );
}
