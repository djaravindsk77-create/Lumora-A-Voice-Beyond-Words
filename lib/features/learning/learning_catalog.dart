import 'dart:math' as math;

import '../../models/learning_activity.dart';

/// The built-in learning activity catalog with per-category question banks.
/// All items are fictional sample content; question generation is local and
/// rule-based (no network needed).
class LearningCatalog {
  LearningCatalog._();

  static const List<LearningActivity> activities = <LearningActivity>[
    LearningActivity(
        id: 'colors-match',
        category: ActivityCategory.colors,
        titleKey: 'learn.colors',
        iconKey: 'palette',
        colorName: 'red',
        descriptionKey: 'learn.chooseAnswer'),
    LearningActivity(
        id: 'shapes-quiz',
        category: ActivityCategory.shapes,
        titleKey: 'learn.shapes',
        iconKey: 'shapes',
        colorName: 'purple'),
    LearningActivity(
        id: 'numbers-count',
        category: ActivityCategory.numbers,
        titleKey: 'learn.numbers',
        iconKey: 'looks_one',
        colorName: 'blue'),
    LearningActivity(
        id: 'alphabets-abc',
        category: ActivityCategory.alphabets,
        titleKey: 'learn.alphabets',
        iconKey: 'abc',
        colorName: 'teal'),
    LearningActivity(
        id: 'animals-quiz',
        category: ActivityCategory.animals,
        titleKey: 'learn.animals',
        iconKey: 'cruelty_free',
        colorName: 'orange'),
    LearningActivity(
        id: 'fruits-quiz',
        category: ActivityCategory.fruits,
        titleKey: 'learn.fruits',
        iconKey: 'nutrition',
        colorName: 'green'),
    LearningActivity(
        id: 'vegetables-quiz',
        category: ActivityCategory.vegetables,
        titleKey: 'learn.vegetables',
        iconKey: 'ecomode',
        colorName: 'green'),
    LearningActivity(
        id: 'vehicles-quiz',
        category: ActivityCategory.vehicles,
        titleKey: 'learn.vehicles',
        iconKey: 'directions_car',
        colorName: 'yellow'),
    LearningActivity(
        id: 'body-parts',
        category: ActivityCategory.bodyParts,
        titleKey: 'learn.bodyParts',
        iconKey: 'accessibility',
        colorName: 'pink'),
    LearningActivity(
        id: 'household-items',
        category: ActivityCategory.household,
        titleKey: 'learn.household',
        iconKey: 'chair',
        colorName: 'brown'),
    LearningActivity(
        id: 'community-helpers',
        category: ActivityCategory.communityHelpers,
        titleKey: 'learn.communityHelpers',
        iconKey: 'groups',
        colorName: 'blue'),
    LearningActivity(
        id: 'basic-words',
        category: ActivityCategory.basicWords,
        titleKey: 'learn.basicWords',
        iconKey: 'abc',
        colorName: 'purple'),
    LearningActivity(
        id: 'matching-pairs',
        category: ActivityCategory.matching,
        titleKey: 'learn.matching',
        iconKey: 'extension',
        colorName: 'teal'),
    LearningActivity(
        id: 'sorting-game',
        category: ActivityCategory.sorting,
        titleKey: 'learn.sorting',
        iconKey: 'sort',
        colorName: 'orange'),
    LearningActivity(
        id: 'memory-cards',
        category: ActivityCategory.memory,
        titleKey: 'learn.memory',
        iconKey: 'psychology',
        colorName: 'purple'),
    LearningActivity(
        id: 'picture-id',
        category: ActivityCategory.pictureId,
        titleKey: 'learn.pictureId',
        iconKey: 'image',
        colorName: 'blue'),
    LearningActivity(
        id: 'puzzles-lite',
        category: ActivityCategory.puzzles,
        titleKey: 'learn.puzzles',
        iconKey: 'extension',
        colorName: 'yellow'),
    LearningActivity(
        id: 'life-skills',
        category: ActivityCategory.lifeSkills,
        titleKey: 'learn.lifeSkills',
        iconKey: 'handyman',
        colorName: 'green'),
  ];

  static LearningActivity? byId(String id) {
    for (final LearningActivity a in activities) {
      if (a.id == id) return a;
    }
    return null;
  }

  // ---- Question banks ------------------------------------------------

  static const Map<String, List<String>> _banks = <String, List<String>>{
    'colors': <String>['Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple'],
    'shapes': <String>['Circle', 'Square', 'Triangle', 'Star', 'Heart'],
    'numbers': <String>['1', '2', '3', '4', '5'],
    'alphabets': <String>['A', 'B', 'C', 'D', 'E'],
    'animals': <String>['Cat', 'Dog', 'Cow', 'Lion', 'Elephant'],
    'fruits': <String>['Apple', 'Banana', 'Mango', 'Grapes'],
    'vegetables': <String>['Carrot', 'Potato', 'Tomato', 'Onion'],
    'vehicles': <String>['Bus', 'Car', 'Train', 'Bicycle'],
    'bodyParts': <String>['Hand', 'Eye', 'Ear', 'Foot'],
    'household': <String>['Chair', 'Cup', 'Fan', 'Lamp'],
    'communityHelpers': <String>['Doctor', 'Teacher', 'Farmer', 'Police'],
    'basicWords': <String>['Water', 'Food', 'Home', 'Play'],
  };

  static const Map<String, List<String>> _banksTa = <String, List<String>>{
    'colors': <String>['சிவப்பு', 'நீலம்', 'பச்சை', 'மஞ்சள்', 'ஆரஞ்சு', 'ஊதா'],
    'shapes': <String>['வட்டம்', 'சதுரம்', 'முக்கோணம்', 'நட்சத்திரம்', 'இதயம்'],
    'numbers': <String>['1', '2', '3', '4', '5'],
    'alphabets': <String>['அ', 'ஆ', 'இ', 'ஈ', 'உ'],
    'animals': <String>['பூனை', 'நாய்', 'மாடு', 'சிங்கம்', 'யானை'],
    'fruits': <String>['ஆப்பிள்', 'வாழை', 'மாம்பழம்', 'திராட்சை'],
    'vegetables': <String>['கேரட்', 'உருளை', 'தக்காளி', 'வெங்காயம்'],
    'vehicles': <String>['பஸ்', 'கார்', 'ரயில்', 'சைக்கிள்'],
    'bodyParts': <String>['கை', 'கண்', 'காது', 'கால்'],
    'household': <String>['நாற்காலி', 'கப்', 'மின்விசிறி', 'விளக்கு'],
    'communityHelpers': <String>['மருத்துவர்', 'ஆசிரியர்', 'விவசாயி', 'காவலர்'],
    'basicWords': <String>['தண்ணீர்', 'உணவு', 'வீடு', 'விளையாட்டு'],
  };

  /// Generates [count] multiple-choice questions for [activity] at
  /// [level]. Deterministic given [seed] so tests are stable.
  static List<ActivityQuestion> generateQuiz({
    required LearningActivity activity,
    required LearningLevel level,
    required String languageCode,
    int count = 5,
    int seed = 7,
  }) {
    final math.Random rnd = math.Random(seed);
    final List<String> bank =
        (languageCode == 'ta'
                ? _banksTa[activity.category.id]
                : _banks[activity.category.id]) ??
            _banks['colors']!;
    final int optionCount = level == LearningLevel.beginner
        ? 2
        : level == LearningLevel.intermediate
            ? 3
            : 4;
    final List<ActivityQuestion> out = <ActivityQuestion>[];
    for (int i = 0; i < count; i++) {
      final String answer = bank[rnd.nextInt(bank.length)];
      final List<String> options = <String>[answer];
      while (options.length < optionCount) {
        final String candidate = bank[rnd.nextInt(bank.length)];
        if (!options.contains(candidate)) options.add(candidate);
      }
      options.shuffle(rnd);
      out.add(ActivityQuestion(
        promptKey: 'learn.chooseAnswer',
        promptParams: const <String, String>{},
        answer: answer,
        options: options,
        speakText: answer,
      ));
    }
    return out;
  }
}
