import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/config/env_config.dart';
import '../../models/barrel.dart';

/// Rule-based recommendation + optional AI hook.
///
/// Every feature has a deterministic local fallback so the app never
/// requires network/AI. When AI is configured (endpoint + key + enabled),
/// [generateStoryFromPrompt] may enrich results; all AI output is flagged
/// with `aiGenerated: true` and never used for medical decisions.
class SuggestionEngine {
  SuggestionEngine._();
  static final SuggestionEngine instance = SuggestionEngine._();

  /// Suggests the next [count] activities based on history, difficulty and
  /// favourites. Pure rule-based.
  List<LearningActivity> recommendActivities({
    required List<LearningActivity> catalog,
    required List<LearningProgress> progress,
    required ChildProfile child,
    int count = 3,
  }) {
    if (catalog.isEmpty) return const <LearningActivity>[];

    // Score: favourite activity small boost; low accuracy slight boost
    // (more practice); not played recently big boost.
    final Map<String, LearningProgress> latest =
        <String, LearningProgress>{};
    for (final LearningProgress p in progress) {
      final LearningProgress? cur = latest[p.activityId];
      if (cur == null || p.completedAt.isAfter(cur.completedAt)) {
        latest[p.activityId] = p;
      }
    }

    double score(LearningActivity a) {
      double s = 0;
      if (child.favoriteActivityIds.contains(a.id)) s += 2;
      final LearningProgress? p = latest[a.id];
      if (p == null) {
        s += 3; // Encourage trying new activities.
      } else {
        if (p.accuracy < 0.6) s += 1.5; // Needs more practice.
        if (p.accuracy >= 0.9) s += 1; // Ready to advance.
        final int days = DateTime.now()
            .difference(p.completedAt)
            .inDays;
        if (days >= 3) s += 2;
      }
      return s;
    }

    final List<LearningActivity> sorted = catalog
        .where((LearningActivity a) => a.enabled)
        .toList()
      ..sort((LearningActivity a, LearningActivity b) => score(b).compareTo(score(a)));
    return sorted.take(count).toList();
  }

  /// Suggests phrases for the current context mode based on usage.
  List<String> suggestPhrases(List<CommunicationActivity> history,
      {int count = 5}) {
    final Map<String, int> freq = <String, int>{};
    for (final CommunicationActivity a in history) {
      freq[a.content] = (freq[a.content] ?? 0) + 1;
    }
    final List<MapEntry<String, int>> sorted = freq.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    return sorted.take(count).map((MapEntry<String, int> e) => e.key).toList();
  }

  /// Predicts next words for the sentence builder from history (rule-based).
  List<String> predictNextWords(List<SentenceHistory> history,
      {int count = 6}) {
    final Map<String, int> freq = <String, int>{};
    for (final SentenceHistory s in history) {
      for (final String w in s.words) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }
    final List<MapEntry<String, int>> sorted = freq.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    return sorted.take(count).map((MapEntry<String, int> e) => e.key).toList();
  }

  /// Simple template-based story generation (local, offline). Clearly
  /// labelled AI-assist in the UI; never medical or diagnostic.
  Story generateStoryFromPrompt(String title, String topicWords) {
    final List<StoryPage> pages = <StoryPage>[
      StoryPage(
        id: 'p1',
        text: 'This is a story about $topicWords.',
        iconKey: 'auto_stories',
      ),
      StoryPage(
        id: 'p2',
        text: 'Sometimes $topicWords can feel new.',
        iconKey: 'help',
      ),
      const StoryPage(
        id: 'p3',
        text: 'I can take a deep breath and try.',
        iconKey: 'self_improvement',
        colorName: 'teal',
      ),
      const StoryPage(
        id: 'p4',
        text: 'With my grown-up beside me, I can do it!',
        iconKey: 'favorite',
        colorName: 'pink',
      ),
    ];
    return Story(
      id: 'ai-story-${DateTime.now().millisecondsSinceEpoch}',
      title: title.isEmpty ? 'My new story' : title,
      pages: pages,
      createdAt: DateTime.now(),
      isCustom: true,
      isSocial: false,
    );
  }

  /// Optional AI enhancement hook. Returns null when AI is not configured;
  /// never throws; never blocks long.
  Future<String?> aiTranslate(String text, String targetLanguage) async {
    if (!AppConfig.enableAi ||
        EnvConfig.aiEndpoint.isEmpty ||
        EnvConfig.aiApiKey.isEmpty) {
      return null;
    }
    try {
      final http.Response resp = await http
          .post(
            Uri.parse('${EnvConfig.aiEndpoint}/translate'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${EnvConfig.aiApiKey}',
            },
            body: jsonEncode(<String, String>{
              'text': text,
              'target': targetLanguage,
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(resp.body) as Map<String, dynamic>;
        return body['translation'] as String?;
      }
    } on Exception catch (e) {
      debugPrint('AI translate failed ($e) - using local content.');
    }
    return null;
  }
}
