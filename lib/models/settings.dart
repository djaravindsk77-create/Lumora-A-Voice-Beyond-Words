import 'package:flutter/foundation.dart';

/// Accessibility preferences captured during onboarding and editable in
/// Settings. All UI respects these values.
@immutable
class AccessibilitySettings {
  const AccessibilitySettings({
    this.textScale = 1.0,
    this.highContrast = false,
    this.reducedMotion = false,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.largeButtons = false,
  });

  final double textScale;
  final bool highContrast;
  final bool reducedMotion;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool largeButtons;

  static const double minScale = 1.0;
  static const double maxScale = 1.8;

  AccessibilitySettings copyWith({
    double? textScale,
    bool? highContrast,
    bool? reducedMotion,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? largeButtons,
  }) =>
      AccessibilitySettings(
        textScale: textScale ?? this.textScale,
        highContrast: highContrast ?? this.highContrast,
        // Must fall back to the current value: the old `reducedMotion == true`
        // form silently reset reduced motion whenever any other setting (for
        // example the text size) was changed.
        reducedMotion: reducedMotion ?? this.reducedMotion,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        largeButtons: largeButtons ?? this.largeButtons,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'textScale': textScale,
        'highContrast': highContrast,
        'reducedMotion': reducedMotion,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'largeButtons': largeButtons,
      };

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) =>
      AccessibilitySettings(
        textScale:
            (json['textScale'] as num?)?.toDouble() ?? 1.0,
        highContrast: json['highContrast'] as bool? ?? false,
        reducedMotion: json['reducedMotion'] as bool? ?? false,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
        largeButtons: json['largeButtons'] as bool? ?? false,
      );

  /// Presets offered during onboarding.
  static const AccessibilitySettings presetDefault = AccessibilitySettings();

  static const AccessibilitySettings presetLarge = AccessibilitySettings(
    textScale: 1.3,
    largeButtons: true,
  );

  static const AccessibilitySettings presetCalm = AccessibilitySettings(
    reducedMotion: true,
    soundEnabled: false,
    hapticsEnabled: false,
  );

  static const AccessibilitySettings presetHighContrast =
      AccessibilitySettings(
    highContrast: true,
    textScale: 1.15,
    largeButtons: true,
  );
}

/// Lightweight app-wide settings stored in SharedPreferences.
@immutable
class AppSettings {
  const AppSettings({
    this.languageCode = 'en',
    this.themeMode = 'system',
    this.onboardingComplete = false,
    this.lastRole = 'child',
    this.lastChildId = '',
    this.signedInUserJson,
    this.notifRoutine = true,
    this.notifActivity = true,
    this.notifAlerts = true,
    this.notifAssigned = true,
    this.notifNotes = true,
    this.notifEvents = true,
    this.quietHoursEnabled = false,
    this.quietStartMinutes = 21 * 60,
    this.quietEndMinutes = 7 * 60,
    this.trackingEnabled = true,
    this.locationConsent = false,
    this.micConsent = false,
    this.photoConsent = false,
    this.modeSuggestionsEnabled = true,
    this.defaultModeId = 'home',
  });

  final String languageCode;
  final String themeMode; // light | dark | system
  final bool onboardingComplete;
  final String lastRole;
  final String lastChildId;

  // Notification preferences.
  final bool notifRoutine;
  final bool notifActivity;
  final bool notifAlerts;
  final bool notifAssigned;
  final bool notifNotes;
  final bool notifEvents;

  // Quiet hours.
  final bool quietHoursEnabled;
  final int quietStartMinutes;
  final int quietEndMinutes;

  // Privacy / consent.
  final bool trackingEnabled;
  final bool locationConsent;
  final bool micConsent;
  final bool photoConsent;

  // Context modes.
  final bool modeSuggestionsEnabled;
  final String defaultModeId;

  /// JSON of the signed-in [UserModel]. Persisted so the session survives
  /// app restarts; cleared only when the user taps Sign out.

  /// JSON of the signed-in [UserModel]. Persisted so the session survives
  /// app restarts; cleared only when the user taps Sign out.
  final String? signedInUserJson;

  /// Sentinel so [copyWith] can distinguish "keep current" from "clear to
  /// null" for the nullable session field.
  static const Object _unset = Object();

  AppSettings copyWith({
    String? languageCode,
    String? themeMode,
    bool? onboardingComplete,
    String? lastRole,
    String? lastChildId,
    bool? notifRoutine,
    bool? notifActivity,
    bool? notifAlerts,
    bool? notifAssigned,
    bool? notifNotes,
    bool? notifEvents,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
    bool? trackingEnabled,
    bool? locationConsent,
    bool? micConsent,
    bool? photoConsent,
    bool? modeSuggestionsEnabled,
    String? defaultModeId,
    Object? signedInUserJson = _unset,
  }) =>
      AppSettings(
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastRole: lastRole ?? this.lastRole,
        lastChildId: lastChildId ?? this.lastChildId,
        signedInUserJson: signedInUserJson == _unset
            ? this.signedInUserJson
            : signedInUserJson as String?,
        notifRoutine: notifRoutine ?? this.notifRoutine,
        notifActivity: notifActivity ?? this.notifActivity,
        notifAlerts: notifAlerts ?? this.notifAlerts,
        notifAssigned: notifAssigned ?? this.notifAssigned,
        notifNotes: notifNotes ?? this.notifNotes,
        notifEvents: notifEvents ?? this.notifEvents,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
        quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
        trackingEnabled: trackingEnabled ?? this.trackingEnabled,
        locationConsent: locationConsent ?? this.locationConsent,
        micConsent: micConsent ?? this.micConsent,
        photoConsent: photoConsent ?? this.photoConsent,
        modeSuggestionsEnabled:
            modeSuggestionsEnabled ?? this.modeSuggestionsEnabled,
        defaultModeId: defaultModeId ?? this.defaultModeId,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'languageCode': languageCode,
        'themeMode': themeMode,
        'onboardingComplete': onboardingComplete,
        'lastRole': lastRole,
        'lastChildId': lastChildId,
        'notifRoutine': notifRoutine,
        'notifActivity': notifActivity,
        'notifAlerts': notifAlerts,
        'notifAssigned': notifAssigned,
        'notifNotes': notifNotes,
        'notifEvents': notifEvents,
        'quietHoursEnabled': quietHoursEnabled,
        'quietStartMinutes': quietStartMinutes,
        'quietEndMinutes': quietEndMinutes,
        'trackingEnabled': trackingEnabled,
        'locationConsent': locationConsent,
        'micConsent': micConsent,
        'photoConsent': photoConsent,
        'modeSuggestionsEnabled': modeSuggestionsEnabled,
        'defaultModeId': defaultModeId,
        'signedInUserJson': signedInUserJson,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        languageCode: json['languageCode'] as String? ?? 'en',
        themeMode: json['themeMode'] as String? ?? 'system',
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        lastRole: json['lastRole'] as String? ?? 'child',
        lastChildId: json['lastChildId'] as String? ?? '',
        notifRoutine: json['notifRoutine'] as bool? ?? true,
        notifActivity: json['notifActivity'] as bool? ?? true,
        notifAlerts: json['notifAlerts'] as bool? ?? true,
        notifAssigned: json['notifAssigned'] as bool? ?? true,
        notifNotes: json['notifNotes'] as bool? ?? true,
        notifEvents: json['notifEvents'] as bool? ?? true,
        quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
        quietStartMinutes:
            (json['quietStartMinutes'] as num?)?.toInt() ?? 21 * 60,
        quietEndMinutes:
            (json['quietEndMinutes'] as num?)?.toInt() ?? 7 * 60,
        trackingEnabled: json['trackingEnabled'] as bool? ?? true,
        locationConsent: json['locationConsent'] as bool? ?? false,
        micConsent: json['micConsent'] as bool? ?? false,
        photoConsent: json['photoConsent'] as bool? ?? false,
        modeSuggestionsEnabled:
            json['modeSuggestionsEnabled'] as bool? ?? true,
        defaultModeId: json['defaultModeId'] as String? ?? 'home',
        signedInUserJson: json['signedInUserJson'] as String?,
      );
}
