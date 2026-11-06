import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../models/barrel.dart';

/// Offline-first local data source backed by Hive.
///
/// Every collection is stored as JSON strings keyed by id, which keeps the
/// schema flexible and makes model changes painless. All getters are
/// synchronous after [init] because Hive reads from memory.
class LocalDataSource {
  LocalDataSource._();
  static final LocalDataSource instance = LocalDataSource._();

  static const Uuid _uuid = Uuid();
  bool _initialized = false;

  final Map<String, Box<String>> _boxes = <String, Box<String>>{};

  Future<void> init() async {
    if (_initialized) return;
    // Required on mobile/desktop: points Hive at the app documents directory
    // (web uses IndexedDB and this is a no-op there).
    await Hive.initFlutter('lumora');
    for (final String name in AppConstants.allBoxes) {
      _boxes[name] = await Hive.openBox<String>(name);
    }
    _initialized = true;
  }

  bool get isReady => _initialized;

  String newId() => _uuid.v4();

  Box<String> _b(String name) {
    final Box<String>? b = _boxes[name];
    if (b == null || !b.isOpen) {
      throw StateError('LocalDataSource not initialised. Call init() first.');
    }
    return b;
  }

  // ------------------------------------------------------------------
  // Generic helpers
  // ------------------------------------------------------------------

  List<T> _all<T>(String boxName, T Function(Map<String, dynamic>) fromJson) {
    final Box<String> b = _b(boxName);
    final List<T> out = <T>[];
    for (final String raw in b.values) {
      try {
        out.add(fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } on FormatException {
        // Skip corrupted entries instead of crashing the app.
        continue;
      }
    }
    return out;
  }

  T? _get<T>(String boxName, String id,
      T Function(Map<String, dynamic>) fromJson) {
    final String? raw = _b(boxName).get(id);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> _put(String boxName, String id, Map<String, dynamic> json) =>
      _b(boxName).put(id, jsonEncode(json));

  Future<void> _delete(String boxName, String id) => _b(boxName).delete(id);

  int _count(String boxName) => _b(boxName).length;

  // ------------------------------------------------------------------
  // Children
  // ------------------------------------------------------------------

  List<ChildProfile> getChildren() =>
      _all<ChildProfile>(AppConstants.boxChildren, ChildProfile.fromJson);

  ChildProfile? getChild(String id) =>
      _get<ChildProfile>(AppConstants.boxChildren, id, ChildProfile.fromJson);

  Future<void> saveChild(ChildProfile child) =>
      _put(AppConstants.boxChildren, child.id, child.toJson());

  Future<void> deleteChild(String id) async {
    await _delete(AppConstants.boxChildren, id);
  }

  // ------------------------------------------------------------------
  // Users (demo accounts / profiles)
  // ------------------------------------------------------------------

  List<UserModel> getUsers() =>
      _all<UserModel>(AppConstants.boxUsers, UserModel.fromJson);

  Future<void> saveUser(UserModel user) =>
      _put(AppConstants.boxUsers, user.id, user.toJson());

  // ------------------------------------------------------------------
  // AAC categories & cards
  // ------------------------------------------------------------------

  List<PictureCategory> getCategories() => _all<PictureCategory>(
      AppConstants.boxCategories, PictureCategory.fromJson);

  PictureCategory? getCategory(String id) => _get<PictureCategory>(
      AppConstants.boxCategories, id, PictureCategory.fromJson);

  Future<void> saveCategory(PictureCategory c) =>
      _put(AppConstants.boxCategories, c.id, c.toJson());

  Future<void> deleteCategory(String id) =>
      _delete(AppConstants.boxCategories, id);

  List<PictureCard> getCards() =>
      _all<PictureCard>(AppConstants.boxCards, PictureCard.fromJson);

  PictureCard? getCard(String id) =>
      _get<PictureCard>(AppConstants.boxCards, id, PictureCard.fromJson);

  Future<void> saveCard(PictureCard card) =>
      _put(AppConstants.boxCards, card.id, card.toJson());

  Future<void> deleteCard(String id) => _delete(AppConstants.boxCards, id);

  int get cardCount => _count(AppConstants.boxCards);

  // ------------------------------------------------------------------
  // Saved phrases & sentence history
  // ------------------------------------------------------------------

  List<SavedPhrase> getPhrases() =>
      _all<SavedPhrase>(AppConstants.boxPhrases, SavedPhrase.fromJson);

  SavedPhrase? getPhrase(String id) =>
      _get<SavedPhrase>(AppConstants.boxPhrases, id, SavedPhrase.fromJson);

  Future<void> savePhrase(SavedPhrase p) =>
      _put(AppConstants.boxPhrases, p.id, p.toJson());

  Future<void> deletePhrase(String id) =>
      _delete(AppConstants.boxPhrases, id);

  List<SentenceHistory> getSentences() => _all<SentenceHistory>(
      AppConstants.boxSentences, SentenceHistory.fromJson);

  Future<void> saveSentence(SentenceHistory s) =>
      _put(AppConstants.boxSentences, s.id, s.toJson());

  Future<void> deleteSentence(String id) =>
      _delete(AppConstants.boxSentences, id);

  // ------------------------------------------------------------------
  // Emotions
  // ------------------------------------------------------------------

  List<EmotionEntry> getEmotionEntries() =>
      _all<EmotionEntry>(AppConstants.boxEmotions, EmotionEntry.fromJson);

  Future<void> saveEmotionEntry(EmotionEntry e) =>
      _put(AppConstants.boxEmotions, e.id, e.toJson());

  Future<void> deleteEmotionEntry(String id) =>
      _delete(AppConstants.boxEmotions, id);

  // ------------------------------------------------------------------
  // Communication activity log
  // ------------------------------------------------------------------

  List<CommunicationActivity> getCommActivities() => _all<
          CommunicationActivity>(
      AppConstants.boxCommunication, CommunicationActivity.fromJson);

  Future<void> saveCommActivity(CommunicationActivity a) =>
      _put(AppConstants.boxCommunication, a.id, a.toJson());

  Future<void> deleteCommActivity(String id) =>
      _delete(AppConstants.boxCommunication, id);

  // ------------------------------------------------------------------
  // Routines & completions
  // ------------------------------------------------------------------

  List<Routine> getRoutines() =>
      _all<Routine>(AppConstants.boxRoutines, Routine.fromJson);

  Routine? getRoutine(String id) =>
      _get<Routine>(AppConstants.boxRoutines, id, Routine.fromJson);

  Future<void> saveRoutine(Routine r) =>
      _put(AppConstants.boxRoutines, r.id, r.toJson());

  Future<void> deleteRoutine(String id) =>
      _delete(AppConstants.boxRoutines, id);

  List<RoutineCompletion> getRoutineCompletions() =>
      _all<RoutineCompletion>(
          AppConstants.boxNotes, RoutineCompletion.fromJson);

  Future<void> saveRoutineCompletion(RoutineCompletion rc) =>
      _put(AppConstants.boxNotes, 'rc-${rc.id}', rc.toJson());

  // ------------------------------------------------------------------
  // Reminders
  // ------------------------------------------------------------------

  List<Reminder> getReminders() =>
      _all<Reminder>(AppConstants.boxReminders, Reminder.fromJson);

  Future<void> saveReminder(Reminder r) =>
      _put(AppConstants.boxReminders, r.id, r.toJson());

  Future<void> deleteReminder(String id) =>
      _delete(AppConstants.boxReminders, id);

  // ------------------------------------------------------------------
  // Trusted contacts
  // ------------------------------------------------------------------

  List<TrustedContact> getContacts() =>
      _all<TrustedContact>(AppConstants.boxContacts, TrustedContact.fromJson);

  Future<void> saveContact(TrustedContact c) =>
      _put(AppConstants.boxContacts, c.id, c.toJson());

  Future<void> deleteContact(String id) =>
      _delete(AppConstants.boxContacts, id);

  // ------------------------------------------------------------------
  // Safety alerts
  // ------------------------------------------------------------------

  List<SafetyAlert> getAlerts() =>
      _all<SafetyAlert>(AppConstants.boxAlerts, SafetyAlert.fromJson);

  Future<void> saveAlert(SafetyAlert a) =>
      _put(AppConstants.boxAlerts, a.id, a.toJson());

  Future<void> deleteAlert(String id) => _delete(AppConstants.boxAlerts, id);

  // ------------------------------------------------------------------
  // Notifications
  // ------------------------------------------------------------------

  List<NotificationItem> getNotifications() => _all<NotificationItem>(
      AppConstants.boxNotifications, NotificationItem.fromJson);

  Future<void> saveNotification(NotificationItem n) =>
      _put(AppConstants.boxNotifications, n.id, n.toJson());

  Future<void> deleteNotification(String id) =>
      _delete(AppConstants.boxNotifications, id);

  // ------------------------------------------------------------------
  // Learning progress (persisted across restarts)
  // ------------------------------------------------------------------

  List<LearningProgress> getLearningProgress() =>
      _all<LearningProgress>(
          AppConstants.boxLearningProgress, LearningProgress.fromJson);

  Future<void> saveLearningProgress(LearningProgress p) =>
      _put(AppConstants.boxLearningProgress, p.id, p.toJson());

  Future<void> deleteLearningProgress(String id) =>
      _delete(AppConstants.boxLearningProgress, id);

  // ------------------------------------------------------------------
  // Caregiver notes (teacher/therapist/parent)
  // ------------------------------------------------------------------

  List<CaregiverNote> getNotes() =>
      _all<CaregiverNote>(AppConstants.boxNotes, CaregiverNote.fromJson);

  Future<void> saveNote(CaregiverNote n) =>
      _put(AppConstants.boxNotes, n.id, n.toJson());

  Future<void> deleteNote(String id) => _delete(AppConstants.boxNotes, id);

  // ------------------------------------------------------------------
  // Caregiver permissions (invites / sharing)
  // ------------------------------------------------------------------

  List<CaregiverPermission> getPermissions() => _all<CaregiverPermission>(
      AppConstants.boxPermissions, CaregiverPermission.fromJson);

  Future<void> savePermission(CaregiverPermission p) =>
      _put(AppConstants.boxPermissions, p.id, p.toJson());

  Future<void> deletePermission(String id) =>
      _delete(AppConstants.boxPermissions, id);

  // ------------------------------------------------------------------
  // Pending sync operations (offline queue)
  // ------------------------------------------------------------------

  Map<String, Map<String, dynamic>> getPendingOps() {
    final Box<String> b = _b(AppConstants.boxPendingOps);
    final Map<String, Map<String, dynamic>> out =
        <String, Map<String, dynamic>>{};
    b.toMap().forEach((dynamic key, dynamic raw) {
      if (raw is! String) return;
      try {
        out[key as String] = jsonDecode(raw) as Map<String, dynamic>;
      } on FormatException {
        return;
      }
    });
    return out;
  }

  Future<void> addPendingOp({
    required String collection,
    required String opType,
    required String recordId,
    Map<String, dynamic>? payload,
  }) async {
    final String key = newId();
    await _b(AppConstants.boxPendingOps).put(
      key,
      jsonEncode(<String, dynamic>{
        'collection': collection,
        'opType': opType,
        'recordId': recordId,
        'payload': payload,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> removePendingOp(String key) =>
      _b(AppConstants.boxPendingOps).delete(key);

  Future<void> clearPendingOps() =>
      _b(AppConstants.boxPendingOps).clear();

  int get pendingOpCount => _count(AppConstants.boxPendingOps);

  // ------------------------------------------------------------------
  // Maintenance
  // ------------------------------------------------------------------

  /// Deletes every locally stored record (used by "Delete all local data").
  Future<void> wipeAll() async {
    for (final String name in AppConstants.allBoxes) {
      await _b(name).clear();
    }
  }

  /// Clears only history/log collections, keeping profiles & content.
  Future<void> clearHistory() async {
    await _b(AppConstants.boxSentences).clear();
    await _b(AppConstants.boxEmotions).clear();
    await _b(AppConstants.boxCommunication).clear();
    await _b(AppConstants.boxAlerts).clear();
    await _b(AppConstants.boxNotifications).clear();
  }

  /// Checks whether the given collection box is empty (used by demo seeding).
  bool isCollectionEmpty(String boxName) =>
      _b(boxName).isEmpty;
}
