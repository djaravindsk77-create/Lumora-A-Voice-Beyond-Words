/// Application-wide constants: storage keys, Hive boxes and asset paths.
library;

class AppConstants {
  AppConstants._();

  // ---- SharedPreferences keys (lightweight settings) ----
  static const String spOnboardingComplete = 'lumora.onboarding.complete';
  static const String spLanguage = 'lumora.settings.language';
  static const String spThemeMode = 'lumora.settings.themeMode';
  static const String spAccessibility = 'lumora.settings.accessibility';
  static const String spLastRole = 'lumora.session.lastRole';
  static const String spLastChildId = 'lumora.session.lastChildId';
  static const String spDataMode = 'lumora.settings.dataMode';
  static const String spSoundEnabled = 'lumora.settings.sound';
  static const String spHapticsEnabled = 'lumora.settings.haptics';

  // ---- Hive boxes ----
  static const String boxSettings = 'lumora_settings';
  static const String boxChildren = 'lumora_children';
  static const String boxUsers = 'lumora_users';
  static const String boxCards = 'lumora_cards';
  static const String boxCategories = 'lumora_categories';
  static const String boxPhrases = 'lumora_phrases';
  static const String boxSentences = 'lumora_sentences';
  static const String boxEmotions = 'lumora_emotions';
  static const String boxActivities = 'lumora_activities';
  static const String boxCommunication = 'lumora_communication';
  static const String boxRoutines = 'lumora_routines';
  static const String boxReminders = 'lumora_reminders';
  static const String boxContacts = 'lumora_contacts';
  static const String boxAlerts = 'lumora_alerts';
  static const String boxNotifications = 'lumora_notifications';
  static const String boxNotes = 'lumora_notes';
  static const String boxPermissions = 'lumora_permissions';
  static const String boxLearningProgress = 'lumora_learning_progress';
  static const String boxPendingOps = 'lumora_pending_ops';

  /// All boxes created on startup.
  static const List<String> allBoxes = <String>[
    boxSettings,
    boxChildren,
    boxUsers,
    boxCards,
    boxCategories,
    boxPhrases,
    boxSentences,
    boxEmotions,
    boxActivities,
    boxCommunication,
    boxRoutines,
    boxReminders,
    boxContacts,
    boxAlerts,
    boxNotifications,
    boxNotes,
    boxPermissions,
    boxLearningProgress,
    boxPendingOps,
  ];

  // ---- Assets ----
  /// Demo content is seeded from lib/data/demo/demo_data.dart (icon-based, no
  /// binary assets needed). The JSON files under assets/sample_data/ document
  /// the same schema for tools and offline reference; keep ids in sync if you
  /// add entries there.
  static const String assetImages = 'assets/images/';
  static const String assetSampleData = 'assets/sample_data/';

  // ---- TTS ----
  static const double defaultSpeechRate = 0.45;
  static const double defaultSpeechVolume = 1.0;
  static const double defaultSpeechPitch = 1.0;

  // ---- Dates ----
  static const String isoDateFormat = 'yyyy-MM-dd';
}
