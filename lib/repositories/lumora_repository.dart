import '../core/config/app_config.dart';
import '../models/barrel.dart';
import '../data/demo/demo_data_source.dart';
import '../data/firebase/firebase_data_source.dart';
import '../data/local/local_data_source.dart';

/// Unified repository the UI talks to.
///
/// Today all reads/writes flow to the offline local store (which Demo Mode
/// seeds with fictional data). When Firebase is configured AND cloud sync is
/// enabled, writes are additionally mirrored to Firestore through the
/// Firebase data source, and offline operations are queued on failure.
class LumoraRepository {
  LumoraRepository._();
  static final LumoraRepository instance = LumoraRepository._();

  final LocalDataSource local = LocalDataSource.instance;
  final FirebaseDataSource fb = FirebaseDataSource.instance;

  Future<void> init() async {
    await local.init();
    await DemoDataSource.instance.seedIfNeeded(local);
  }

  // ------------------------------------------------------------------
  // Children
  // ------------------------------------------------------------------

  List<ChildProfile> getChildren() => local.getChildren();

  ChildProfile? getChild(String id) => local.getChild(id);

  Future<void> saveChild(ChildProfile child) async {
    await local.saveChild(child);
    await _mirror('children', child.id, child.toJson());
  }

  Future<void> deleteChild(String id) => local.deleteChild(id);

  // ------------------------------------------------------------------
  // Users
  // ------------------------------------------------------------------

  List<UserModel> getUsers() => local.getUsers();

  Future<void> saveUser(UserModel user) => local.saveUser(user);

  // ------------------------------------------------------------------
  // AAC
  // ------------------------------------------------------------------

  List<PictureCategory> getCategories({bool includeHidden = false}) {
    final List<PictureCategory> cats = local.getCategories()
      ..sort((PictureCategory a, PictureCategory b) =>
          a.orderIndex.compareTo(b.orderIndex));
    return includeHidden ? cats : cats.where((c) => !c.isHidden).toList();
  }

  PictureCategory? getCategory(String id) => local.getCategory(id);

  Future<void> saveCategory(PictureCategory c) async {
    await local.saveCategory(c);
    await _mirror('categories', c.id, c.toJson());
  }

  Future<void> deleteCategory(String id) => local.deleteCategory(id);

  List<PictureCard> getCardsForCategory(String categoryId,
      {bool includeHidden = false}) {
    final List<PictureCard> cards = local
        .getCards()
        .where((PictureCard c) => c.categoryId == categoryId)
        .toList()
      ..sort((PictureCard a, PictureCard b) =>
          a.orderIndex.compareTo(b.orderIndex));
    return includeHidden
        ? cards
        : cards.where((PictureCard c) => !c.isHidden).toList();
  }

  List<PictureCard> getAllCards({bool includeHidden = false}) {
    final List<PictureCard> cards = local.getCards()
      ..sort((PictureCard a, PictureCard b) =>
          a.orderIndex.compareTo(b.orderIndex));
    return includeHidden
        ? cards
        : cards.where((PictureCard c) => !c.isHidden).toList();
  }

  List<PictureCard> getFavoriteCards() => local
      .getCards()
      .where((PictureCard c) => c.isFavorite && !c.isHidden)
      .toList()
    ..sort((PictureCard a, PictureCard b) => b.usageCount.compareTo(a.usageCount));

  PictureCard? getCard(String id) => local.getCard(id);

  Future<void> saveCard(PictureCard card) async {
    await local.saveCard(card);
    await _mirror('cards', card.id, card.toJson());
  }

  Future<void> deleteCard(String id) => local.deleteCard(id);

  // ------------------------------------------------------------------
  // Phrases & sentences
  // ------------------------------------------------------------------

  List<SavedPhrase> getPhrases() => local.getPhrases()
    ..sort((SavedPhrase a, SavedPhrase b) => b.usageCount.compareTo(a.usageCount));

  List<SavedPhrase> getFavoritePhrases() => getPhrases()
      .where((SavedPhrase p) => p.isFavorite)
      .toList();

  Future<void> savePhrase(SavedPhrase p) async {
    await local.savePhrase(p);
    await _mirror('phrases', p.id, p.toJson());
  }

  Future<void> deletePhrase(String id) => local.deletePhrase(id);

  List<SentenceHistory> getSentenceHistory() {
    final List<SentenceHistory> list = local.getSentences()
      ..sort((SentenceHistory a, SentenceHistory b) =>
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Future<void> saveSentence(SentenceHistory s) async {
    await local.saveSentence(s);
    await _mirror('sentences', s.id, s.toJson());
  }

  Future<void> deleteSentence(String id) => local.deleteSentence(id);

  // ------------------------------------------------------------------
  // Emotions
  // ------------------------------------------------------------------

  List<EmotionEntry> getEmotionEntries() {
    final List<EmotionEntry> list = local.getEmotionEntries()
      ..sort((EmotionEntry a, EmotionEntry b) =>
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Future<void> saveEmotionEntry(EmotionEntry e) async {
    await local.saveEmotionEntry(e);
    await _mirror('emotions', e.id, e.toJson());
  }

  Future<void> deleteEmotionEntry(String id) =>
      local.deleteEmotionEntry(id);

  // ------------------------------------------------------------------
  // Communication activity
  // ------------------------------------------------------------------

  List<CommunicationActivity> getCommActivities() {
    final List<CommunicationActivity> list = local.getCommActivities()
      ..sort((CommunicationActivity a, CommunicationActivity b) =>
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return list;
  }

  Future<void> saveCommActivity(CommunicationActivity a) async {
    await local.saveCommActivity(a);
    await _mirror('communication', a.id, a.toJson());
  }

  Future<void> deleteCommActivity(String id) =>
      local.deleteCommActivity(id);

  // ------------------------------------------------------------------
  // Routines
  // ------------------------------------------------------------------

  List<Routine> getRoutines() => local.getRoutines();

  Routine? getRoutine(String id) => local.getRoutine(id);

  Future<void> saveRoutine(Routine r) async {
    await local.saveRoutine(r);
    await _mirror('routines', r.id, r.toJson());
  }

  Future<void> deleteRoutine(String id) => local.deleteRoutine(id);

  List<RoutineCompletion> getRoutineCompletions() =>
      local.getRoutineCompletions();

  Future<void> saveRoutineCompletion(RoutineCompletion rc) async {
    await local.saveRoutineCompletion(rc);
    await _mirror('routine_completions', rc.id, rc.toJson());
  }

  // ------------------------------------------------------------------
  // Reminders
  // ------------------------------------------------------------------

  List<Reminder> getReminders() {
    final List<Reminder> list = local.getReminders()
      ..sort((Reminder a, Reminder b) =>
          a.nextOccurrence(DateTime.now())
              .compareTo(b.nextOccurrence(DateTime.now())));
    return list;
  }

  Future<void> saveReminder(Reminder r) async {
    await local.saveReminder(r);
    await _mirror('reminders', r.id, r.toJson());
  }

  Future<void> deleteReminder(String id) => local.deleteReminder(id);

  // ------------------------------------------------------------------
  // Trusted contacts
  // ------------------------------------------------------------------

  List<TrustedContact> getContacts() => local.getContacts()
    ..sort((TrustedContact a, TrustedContact b) =>
        (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0));

  Future<void> saveContact(TrustedContact c) async {
    await local.saveContact(c);
    await _mirror('contacts', c.id, c.toJson());
  }

  Future<void> deleteContact(String id) => local.deleteContact(id);

  // ------------------------------------------------------------------
  // Safety alerts
  // ------------------------------------------------------------------

  List<SafetyAlert> getAlerts() {
    final List<SafetyAlert> list = local.getAlerts()
      ..sort((SafetyAlert a, SafetyAlert b) =>
          b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveAlert(SafetyAlert a) async {
    await local.saveAlert(a);
    await _mirror('alerts', a.id, a.toJson());
  }

  Future<void> deleteAlert(String id) => local.deleteAlert(id);

  // ------------------------------------------------------------------
  // Notifications
  // ------------------------------------------------------------------

  List<NotificationItem> getNotifications() {
    final List<NotificationItem> list = local.getNotifications()
      ..sort((NotificationItem a, NotificationItem b) =>
          b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveNotification(NotificationItem n) async {
    await local.saveNotification(n);
    await _mirror('notifications', n.id, n.toJson());
  }

  Future<void> deleteNotification(String id) =>
      local.deleteNotification(id);

  // ------------------------------------------------------------------
  // Learning progress
  // ------------------------------------------------------------------

  List<LearningProgress> getLearningProgress() {
    final List<LearningProgress> list = local.getLearningProgress()
      ..sort((LearningProgress a, LearningProgress b) =>
          b.completedAt.compareTo(a.completedAt));
    return list;
  }

  Future<void> saveLearningProgress(LearningProgress p) async {
    await local.saveLearningProgress(p);
    await _mirror('learning_progress', p.id, p.toJson());
  }

  Future<void> deleteLearningProgress(String id) =>
      local.deleteLearningProgress(id);

  // ------------------------------------------------------------------
  // Notes & permissions
  // ------------------------------------------------------------------

  List<CaregiverNote> getNotes() {
    final List<CaregiverNote> list = local.getNotes()
      ..sort((CaregiverNote a, CaregiverNote b) =>
          b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveNote(CaregiverNote n) async {
    await local.saveNote(n);
    await _mirror('notes', n.id, n.toJson());
  }

  Future<void> deleteNote(String id) => local.deleteNote(id);

  /// Collaborator permissions (invites / sharing) with parent-controlled
  /// granular access. Teachers/therapists only receive what is shared.
  List<CaregiverPermission> getPermissions() => local.getPermissions();

  Future<void> savePermission(CaregiverPermission p) async {
    await local.savePermission(p);
    await _mirror('permissions', p.id, p.toJson());
  }

  Future<void> deletePermission(String id) => local.deletePermission(id);

  // ------------------------------------------------------------------
  // Maintenance
  // ------------------------------------------------------------------

  Future<void> wipeAll() => local.wipeAll();

  Future<void> clearHistory() => local.clearHistory();

  int get pendingOps => local.pendingOpCount;

  /// Mirrors a record to Firestore when cloud sync is enabled. On failure,
  /// queues the operation so it can be retried when connectivity returns.
  Future<void> _mirror(String collection, String id,
      Map<String, dynamic> json) async {
    if (!AppConfig.isFirebaseAvailable || !AppConfig.enableCloudSync) return;
    final bool ok = await fb.pushRecord(collection, id, json);
    if (!ok) {
      await local.addPendingOp(
        collection: collection,
        opType: 'upsert',
        recordId: id,
        payload: json,
      );
    }
  }

  /// Attempts to flush queued operations (called when connectivity returns).
  Future<int> flushPendingOps() async {
    if (!AppConfig.isFirebaseAvailable || !AppConfig.enableCloudSync) {
      return 0;
    }
    final Map<String, Map<String, dynamic>> ops = local.getPendingOps();
    int flushed = 0;
    for (final MapEntry<String, Map<String, dynamic>> e in ops.entries) {
      final Map<String, dynamic> op = e.value;
      final bool ok = await fb.pushRecord(
        op['collection'] as String? ?? 'misc',
        op['recordId'] as String? ?? e.key,
        (op['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
      if (ok) {
        await local.removePendingOp(e.key);
        flushed++;
      }
    }
    return flushed;
  }
}
