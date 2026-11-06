import 'package:flutter/foundation.dart';

/// A picture card on the AAC board.
@immutable
class PictureCard {
  const PictureCard({
    required this.id,
    required this.categoryId,
    required this.labelEn,
    this.labelTa,
    this.speechText,
    this.iconKey = 'star',
    this.colorName = 'blue',
    this.customImagePath,
    this.customAudioPath,
    this.isCustom = false,
    this.isFavorite = false,
    this.isHidden = false,
    this.usageCount = 0,
    this.orderIndex = 0,
    this.aiGenerated = false,
  });

  final String id;
  final String categoryId;

  /// English label (display label for the current language is resolved by
  /// the UI based on [labelTa] and the active locale).
  final String labelEn;
  final String? labelTa;

  /// Text spoken by TTS; defaults to the display label.
  final String? speechText;
  final String iconKey;
  final String colorName;

  /// Local file path for a parent-uploaded photo (null for icon cards).
  final String? customImagePath;

  /// Local file path for caregiver-recorded audio. Null means "use TTS".
  final String? customAudioPath;

  final bool isCustom;
  final bool isFavorite;
  final bool isHidden;
  final int usageCount;
  final int orderIndex;

  /// True when the card was produced by the AI-assist feature, so the UI can
  /// clearly indicate AI-generated content.
  final bool aiGenerated;

  String label(String languageCode) {
    if (languageCode == 'ta' &&
        labelTa != null &&
        labelTa!.trim().isNotEmpty) {
      return labelTa!;
    }
    return labelEn;
  }

  PictureCard copyWith({
    String? labelEn,
    String? labelTa,
    String? speechText,
    String? iconKey,
    String? colorName,
    String? customImagePath,
    String? customAudioPath,
    bool? isFavorite,
    bool? isHidden,
    int? usageCount,
    int? orderIndex,
    bool? aiGenerated,
  }) =>
      PictureCard(
        id: id,
        categoryId: categoryId,
        labelEn: labelEn ?? this.labelEn,
        labelTa: labelTa ?? this.labelTa,
        speechText: speechText ?? this.speechText,
        iconKey: iconKey ?? this.iconKey,
        colorName: colorName ?? this.colorName,
        customImagePath: customImagePath ?? this.customImagePath,
        customAudioPath: customAudioPath ?? this.customAudioPath,
        isCustom: isCustom,
        isFavorite: isFavorite ?? this.isFavorite,
        isHidden: isHidden ?? this.isHidden,
        usageCount: usageCount ?? this.usageCount,
        orderIndex: orderIndex ?? this.orderIndex,
        aiGenerated: aiGenerated ?? this.aiGenerated,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'categoryId': categoryId,
        'labelEn': labelEn,
        'labelTa': labelTa,
        'speechText': speechText,
        'iconKey': iconKey,
        'colorName': colorName,
        'customImagePath': customImagePath,
        'customAudioPath': customAudioPath,
        'isCustom': isCustom,
        'isFavorite': isFavorite,
        'isHidden': isHidden,
        'usageCount': usageCount,
        'orderIndex': orderIndex,
        'aiGenerated': aiGenerated,
      };

  factory PictureCard.fromJson(Map<String, dynamic> json) => PictureCard(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        labelEn: json['labelEn'] as String? ?? '',
        labelTa: json['labelTa'] as String?,
        speechText: json['speechText'] as String?,
        iconKey: json['iconKey'] as String? ?? 'star',
        colorName: json['colorName'] as String? ?? 'blue',
        customImagePath: json['customImagePath'] as String?,
        customAudioPath: json['customAudioPath'] as String?,
        isCustom: json['isCustom'] as bool? ?? false,
        isFavorite: json['isFavorite'] as bool? ?? false,
        isHidden: json['isHidden'] as bool? ?? false,
        usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        aiGenerated: json['aiGenerated'] as bool? ?? false,
      );
}

/// An AAC category (Food, Drinks, Feelings, ...).
@immutable
class PictureCategory {
  const PictureCategory({
    required this.id,
    required this.nameEn,
    this.nameTa,
    this.iconKey = 'grid_view',
    this.colorName = 'blue',
    this.orderIndex = 0,
    this.isHidden = false,
    this.isCustom = false,
  });

  final String id;
  final String nameEn;
  final String? nameTa;
  final String iconKey;
  final String colorName;
  final int orderIndex;
  final bool isHidden;
  final bool isCustom;

  String name(String languageCode) {
    if (languageCode == 'ta' && nameTa != null && nameTa!.trim().isNotEmpty) {
      return nameTa!;
    }
    return nameEn;
  }

  PictureCategory copyWith({
    String? nameEn,
    String? nameTa,
    String? iconKey,
    String? colorName,
    int? orderIndex,
    bool? isHidden,
  }) =>
      PictureCategory(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameTa: nameTa ?? this.nameTa,
        iconKey: iconKey ?? this.iconKey,
        colorName: colorName ?? this.colorName,
        orderIndex: orderIndex ?? this.orderIndex,
        isHidden: isHidden ?? this.isHidden,
        isCustom: isCustom,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'nameEn': nameEn,
        'nameTa': nameTa,
        'iconKey': iconKey,
        'colorName': colorName,
        'orderIndex': orderIndex,
        'isHidden': isHidden,
        'isCustom': isCustom,
      };

  factory PictureCategory.fromJson(Map<String, dynamic> json) =>
      PictureCategory(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String? ?? '',
        nameTa: json['nameTa'] as String?,
        iconKey: json['iconKey'] as String? ?? 'grid_view',
        colorName: json['colorName'] as String? ?? 'blue',
        orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
        isHidden: json['isHidden'] as bool? ?? false,
        isCustom: json['isCustom'] as bool? ?? false,
      );
}
