import '../local/local_data_source.dart';
import 'demo_data.dart';
import '../../models/barrel.dart';

/// Demo data source: seeds the offline store with fictional sample data so
/// the app is immediately usable in Demo Mode (no accounts, no backend).
class DemoDataSource {
  DemoDataSource._();
  static final DemoDataSource instance = DemoDataSource._();

  bool _seeded = false;

  /// Seeds demo content into local storage when a collection is empty.
  /// Runs exactly once per app launch; individual items are only added when
  /// their collection is empty so user edits are never overwritten.
  Future<void> seedIfNeeded(LocalDataSource local) async {
    if (_seeded) return;

    if (local.getChildren().isEmpty) {
      await local.saveChild(DemoData.child);
      await local.saveUser(DemoData.parent);
      await local.saveUser(DemoData.teacher);
      await local.saveUser(DemoData.therapist);
      await local.saveUser(DemoData.caregiver);
    }

    if (local.getCategories().isEmpty) {
      for (final PictureCategory c in DemoData.categories) {
        await local.saveCategory(c);
      }
    }

    if (local.getCards().isEmpty) {
      for (final PictureCard card in DemoData.cards) {
        await local.saveCard(card);
      }
    }

    if (local.getPhrases().isEmpty) {
      for (final SavedPhrase p in DemoData.phrases) {
        await local.savePhrase(p);
      }
    }

    if (local.getContacts().isEmpty) {
      for (final TrustedContact c in DemoData.contacts) {
        await local.saveContact(c);
      }
    }

    if (local.getRoutines().isEmpty) {
      for (final Routine r in DemoData.routines) {
        await local.saveRoutine(r);
      }
    }

    if (local.getReminders().isEmpty) {
      for (final Reminder r in DemoData.reminders) {
        await local.saveReminder(r);
      }
    }

    if (local.getSentences().isEmpty) {
      for (final SentenceHistory s in DemoData.sentences) {
        await local.saveSentence(s);
      }
    }

    if (local.getEmotionEntries().isEmpty) {
      for (final EmotionEntry e in DemoData.emotionEntries) {
        await local.saveEmotionEntry(e);
      }
    }

    if (local.getCommActivities().isEmpty) {
      for (final CommunicationActivity a in DemoData.commActivities) {
        await local.saveCommActivity(a);
      }
    }

    if (local.getAlerts().isEmpty) {
      for (final SafetyAlert a in DemoData.alerts) {
        await local.saveAlert(a);
      }
    }

    if (local.getNotifications().isEmpty) {
      for (final NotificationItem n in DemoData.notifications) {
        await local.saveNotification(n);
      }
    }

    if (local.getNotes().isEmpty) {
      for (final CaregiverNote n in DemoData.notes) {
        await local.saveNote(n);
      }
    }

    if (local.getPermissions().isEmpty) {
      for (final CaregiverPermission p in DemoData.permissions) {
        await local.savePermission(p);
      }
    }

    if (local.getLearningProgress().isEmpty) {
      for (final LearningProgress p in DemoData.learningProgress) {
        await local.saveLearningProgress(p);
      }
    }

    _seeded = true;
  }
}
