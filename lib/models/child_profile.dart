import 'package:flutter/foundation.dart';

/// A child profile managed by a parent.
///
/// Deliberately minimal: Lumora does not collect diagnosis or medical data.
@immutable
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    this.age = 6,
    this.avatarKey = 'sun',
    this.languageCode = 'en',
    this.communicationMethods = const <String>['aac', 'voice'],
    this.favoriteActivityIds = const <String>[],
    this.sensoryPreferences = const <String>[],
    this.comfortPreferences = const <String>[],
    this.learningLevel = 'beginner',
    this.trustedContactIds = const <String>[],
    this.enabledModes = const <String>['home', 'school'],
    this.notifiedEmotionIds = const <String>[],
    this.notifiedNeedIds = const <String>[],
    this.trackingEnabled = true,
    this.homeLayout = const <String>[
      'talk',
      'pictures',
      'needs',
      'feelings',
      'learn',
      'routine',
      'calm',
      'safety',
      'progress',
      'profile',
    ],
    this.largeButtons = false,
  });

  final String id;
  final String name;
  final int age;
  final String avatarKey;
  final String languageCode;
  final List<String> communicationMethods;
  final List<String> favoriteActivityIds;
  final List<String> sensoryPreferences;
  final List<String> comfortPreferences;
  final String learningLevel;
  final List<String> trustedContactIds;
  final List<String> enabledModes;
  final List<String> notifiedEmotionIds;
  final List<String> notifiedNeedIds;
  final bool trackingEnabled;
  final List<String> homeLayout;
  final bool largeButtons;

  ChildProfile copyWith({
    String? name,
    int? age,
    String? avatarKey,
    String? languageCode,
    List<String>? communicationMethods,
    List<String>? favoriteActivityIds,
    List<String>? sensoryPreferences,
    List<String>? comfortPreferences,
    String? learningLevel,
    List<String>? trustedContactIds,
    List<String>? enabledModes,
    List<String>? notifiedEmotionIds,
    List<String>? notifiedNeedIds,
    bool? trackingEnabled,
    List<String>? homeLayout,
    bool? largeButtons,
  }) =>
      ChildProfile(
        id: id,
        name: name ?? this.name,
        age: age ?? this.age,
        avatarKey: avatarKey != null && avatarKey.isNotEmpty
            ? avatarKey
            : this.avatarKey,
        languageCode: languageCode ?? this.languageCode,
        communicationMethods: communicationMethods ?? this.communicationMethods,
        favoriteActivityIds: favoriteActivityIds ?? this.favoriteActivityIds,
        sensoryPreferences: sensoryPreferences ?? this.sensoryPreferences,
        comfortPreferences: comfortPreferences ?? this.comfortPreferences,
        learningLevel: learningLevel ?? this.learningLevel,
        trustedContactIds: trustedContactIds ?? this.trustedContactIds,
        enabledModes: enabledModes ?? this.enabledModes,
        notifiedEmotionIds: notifiedEmotionIds ?? this.notifiedEmotionIds,
        notifiedNeedIds: notifiedNeedIds ?? this.notifiedNeedIds,
        trackingEnabled: trackingEnabled ?? this.trackingEnabled,
        homeLayout: homeLayout ?? this.homeLayout,
        largeButtons: largeButtons ?? this.largeButtons,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'age': age,
        'avatarKey': avatarKey,
        'languageCode': languageCode,
        'communicationMethods': communicationMethods,
        'favoriteActivityIds': favoriteActivityIds,
        'sensoryPreferences': sensoryPreferences,
        'comfortPreferences': comfortPreferences,
        'learningLevel': learningLevel,
        'trustedContactIds': trustedContactIds,
        'enabledModes': enabledModes,
        'notifiedEmotionIds': notifiedEmotionIds,
        'notifiedNeedIds': notifiedNeedIds,
        'trackingEnabled': trackingEnabled,
        'homeLayout': homeLayout,
        'largeButtons': largeButtons,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        age: (json['age'] as num?)?.toInt() ?? 6,
        avatarKey: json['avatarKey'] as String? ?? 'sun',
        languageCode: json['languageCode'] as String? ?? 'en',
        communicationMethods:
            (json['communicationMethods'] as List<dynamic>? ?? const [])
                .cast<String>(),
        favoriteActivityIds:
            (json['favoriteActivityIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        sensoryPreferences:
            (json['sensoryPreferences'] as List<dynamic>? ?? const [])
                .cast<String>(),
        comfortPreferences:
            (json['comfortPreferences'] as List<dynamic>? ?? const [])
                .cast<String>(),
        learningLevel: json['learningLevel'] as String? ?? 'beginner',
        trustedContactIds:
            (json['trustedContactIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        enabledModes:
            (json['enabledModes'] as List<dynamic>? ?? const ['home', 'school'])
                .cast<String>(),
        notifiedEmotionIds:
            (json['notifiedEmotionIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        notifiedNeedIds:
            (json['notifiedNeedIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        trackingEnabled: json['trackingEnabled'] as bool? ?? true,
        homeLayout: (json['homeLayout'] as List<dynamic>? ?? const [])
            .cast<String>(),
        largeButtons: json['largeButtons'] as bool? ?? false,
      );
}
