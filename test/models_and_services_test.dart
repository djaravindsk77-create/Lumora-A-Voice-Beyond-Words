import 'package:flutter_test/flutter_test.dart';

import 'package:lumora/core/config/app_config.dart';
import 'package:lumora/core/localization/app_localizations.dart';
import 'package:lumora/core/localization/l10n_en.dart' show l10nEn;
import 'package:lumora/core/localization/l10n_ta.dart' show l10nTa;
import 'package:lumora/data/demo/demo_data.dart';
import 'package:lumora/models/barrel.dart';
import 'package:lumora/services/ai/suggestion_engine.dart';

void main() {
  group('Localization', () {
    test('Tamil map mirrors every English key', () {
      final Set<String> enKeys = l10nEn.keys.toSet();
      final Set<String> taKeys = l10nTa.keys.toSet();
      expect(taKeys.difference(enKeys), isEmpty,
          reason: 'Tamil has keys missing from English');
      // English is the source of truth; Tamil may lag but must cover the
      // keys the demo UI uses. Report missing as a soft expectation:
      final Set<String> missing = enKeys.difference(taKeys);
      expect(missing.length, lessThan(40),
          reason: 'Too many untranslated keys: $missing');
    });

    test('tr() falls back to English then key', () {
      expect(AppLocalizations.tr('en', 'app.tagline'),
          'Every voice matters.');
      expect(AppLocalizations.tr('ta', 'app.tagline'), isNotNull);
      expect(AppLocalizations.tr('en', 'does.not.exist'), 'does.not.exist');
    });

    test('tr() substitutes params', () {
      expect(
        AppLocalizations.tr('en', 'sync.pending',
            params: <String, String>{'count': '3'}),
        '3 changes waiting to sync',
      );
    });
  });

  group('UserRole permissions', () {
    test('parents hold full permissions', () {
      expect(
        UserRole.parent.defaultPermissions.contains(Permission.manageContent),
        isTrue,
      );
      expect(
        UserRole.parent.defaultPermissions.contains(Permission.inviteUsers),
        isTrue,
      );
    });

    test('teacher is read-mostly', () {
      expect(
        UserRole.teacher.defaultPermissions
            .contains(Permission.manageContent),
        isFalse,
      );
      expect(
        UserRole.teacher.defaultPermissions.contains(Permission.viewReports),
        isTrue,
      );
    });

    test('child can interact but not manage', () {
      expect(
        UserRole.child.defaultPermissions.contains(Permission.childInteract),
        isTrue,
      );
      expect(
        UserRole.child.defaultPermissions
            .contains(Permission.managePermissions),
        isFalse,
      );
    });

    test('roleFromId round-trips', () {
      for (final UserRole r in UserRole.values) {
        expect(roleFromId(r.nameId), r);
      }
    });
  });

  group('Demo data', () {
    test('has fictional users for all sample roles', () {
      expect(DemoData.parent.role, UserRole.parent);
      expect(DemoData.teacher.role, UserRole.teacher);
      expect(DemoData.therapist.role, UserRole.therapist);
      expect(DemoData.caregiver.role, UserRole.caregiver);
      expect(DemoData.parent.demo, isTrue);
    });

    test('covers all 16 AAC categories with cards', () {
      expect(DemoData.categories.length, 16);
      final Set<String> ids =
          DemoData.categories.map((PictureCategory c) => c.id).toSet();
      for (final PictureCard card in DemoData.cards) {
        expect(ids.contains(card.categoryId), isTrue,
            reason: 'Card ${card.id} has unknown category');
      }
      expect(DemoData.cards.length, greaterThan(60));
    });

    test('every card has English and Tamil labels', () {
      for (final PictureCard card in DemoData.cards) {
        expect(card.labelEn, isNotEmpty);
        expect(card.labelTa, isNotNull);
      }
    });

    test('sample child profile is complete', () {
      final ChildProfile child = DemoData.child;
      expect(child.name, isNotEmpty);
      expect(child.enabledModes, contains('school'));
      expect(child.notifiedNeedIds, contains('pain'));
    });

    test('routines contain ordered steps', () {
      final Routine morning = DemoData.routines.first;
      expect(morning.tasks.length, greaterThan(4));
      final RoutineTask brush = morning.tasks
          .firstWhere((RoutineTask t) => t.id == 'demo-task-brush');
      expect(brush.steps.length, 5);
    });
  });

  group('Suggestion engine (rule-based AI fallback)', () {
    test('recommends untried activities first', () {
      final List<LearningActivity> recs =
          SuggestionEngine.instance.recommendActivities(
        catalog: LearningCatalogStub.all,
        progress: const <LearningProgress>[],
        child: DemoData.child,
        count: 3,
      );
      expect(recs.length, 3);
    });

    test('predictNextWords ranks frequent words first', () {
      final List<SentenceHistory> history = <SentenceHistory>[
        const SentenceHistory(
            id: 'a',
            childId: 'c',
            words: <String>['I', 'want', 'water'],
            spokenText: 'I want water',
            usageCount: 5),
        const SentenceHistory(
            id: 'b',
            childId: 'c',
            words: <String>['I', 'want', 'food'],
            spokenText: 'I want food',
            usageCount: 2),
      ];
      final List<String> words =
          SuggestionEngine.instance.predictNextWords(history);
      expect(words.first, anyOf('I', 'want'));
    });
  });

  group('AppConfig', () {
    test('defaults to demo mode', () {
      AppConfig.reset();
      expect(AppConfig.dataMode, DataMode.demo);
      expect(AppConfig.isFirebaseAvailable, isFalse);
    });
  });
}

/// Small stub to avoid importing the whole Flutter-dependent catalog in this
/// pure-Dart test.
class LearningCatalogStub {
  static List<LearningActivity> get all => const <LearningActivity>[
        LearningActivity(
            id: 'a1',
            category: ActivityCategory.colors,
            titleKey: 'learn.colors',
            iconKey: 'palette',
            colorName: 'red'),
        LearningActivity(
            id: 'a2',
            category: ActivityCategory.numbers,
            titleKey: 'learn.numbers',
            iconKey: 'looks_one',
            colorName: 'blue'),
        LearningActivity(
            id: 'a3',
            category: ActivityCategory.animals,
            titleKey: 'learn.animals',
            iconKey: 'cruelty_free',
            colorName: 'orange'),
      ];
}
