import 'package:flutter/material.dart';
import '../core/accessibility/tts_bridge.dart';
import '../models/barrel.dart';
import '../repositories/lumora_repository.dart';
import 'settings_provider.dart';

/// Central communication state shared by Voice, AAC, Needs, Emotions and
/// Sentence Builder screens. Persists attempts for the confidence tracker.
class CommunicationProvider extends ChangeNotifier {
  CommunicationProvider(this._settings);

  final SettingsProvider _settings;
  final LumoraRepository _repo = LumoraRepository.instance;

  String _contextMode = 'home';
  List<SentenceHistory> _history = <SentenceHistory>[];
  List<SavedPhrase> _phrases = <SavedPhrase>[];
  List<CommunicationActivity> _activities = <CommunicationActivity>[];

  String get contextMode => _contextMode;
  List<SentenceHistory> get sentenceHistory => List.unmodifiable(_history);
  List<SavedPhrase> get phrases => List.unmodifiable(_phrases);
  List<CommunicationActivity> get activities => List.unmodifiable(_activities);

  Future<void> load(String childId) async {
    _history = _repo.getSentenceHistory();
    _phrases = _repo.getPhrases();
    _activities = _repo.getCommActivities();
    notifyListeners();
  }

  Future<void> setContextMode(String modeId) async {
    _contextMode = modeId;
    notifyListeners();
  }

  /// Logs a communication attempt (respects the tracking preference).
  Future<void> logAttempt({
    required String childId,
    required CommMethod method,
    required String content,
    bool assisted = false,
  }) async {
    if (!_settings.settings.trackingEnabled) return;
    await _repo.saveCommActivity(CommunicationActivity(
      id: _repo.local.newId(),
      childId: childId,
      method: method,
      content: content,
      assisted: assisted,
      contextMode: _contextMode,
      createdAt: DateTime.now(),
    ));
    _activities = _repo.getCommActivities();
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await TtsBridge.speak(text);
  }

  Future<void> stopSpeaking() => TtsBridge.stop();

  // -- phrases -------------------------------------------------------

  Future<void> savePhrase(String childId, String text,
      {bool favorite = false}) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // Merge with an existing identical phrase.
    for (final SavedPhrase p in _phrases) {
      if (p.text.toLowerCase() == trimmed.toLowerCase()) {
        await _repo.savePhrase(p.copyWith(
          usageCount: p.usageCount + 1,
          lastUsedAt: DateTime.now(),
          isFavorite: favorite || p.isFavorite,
        ));
        _phrases = _repo.getPhrases();
        notifyListeners();
        return;
      }
    }
    await _repo.savePhrase(SavedPhrase(
      id: _repo.local.newId(),
      childId: childId,
      text: trimmed,
      isFavorite: favorite,
      usageCount: 1,
      lastUsedAt: DateTime.now(),
      createdAt: DateTime.now(),
    ));
    _phrases = _repo.getPhrases();
    notifyListeners();
  }

  Future<void> togglePhraseFavorite(SavedPhrase p) async {
    await _repo.savePhrase(p.copyWith(isFavorite: !p.isFavorite));
    _phrases = _repo.getPhrases();
    notifyListeners();
  }

  Future<void> deletePhrase(SavedPhrase p) async {
    await _repo.deletePhrase(p.id);
    _phrases = _repo.getPhrases();
    notifyListeners();
  }

  // -- sentence history ------------------------------------------------

  Future<void> saveSentence(String childId, List<String> words) async {
    if (words.isEmpty) return;
    final String spoken = words.join(' ');
    for (final SentenceHistory s in _history) {
      if (s.spokenText.toLowerCase() == spoken.toLowerCase()) {
        await _repo.saveSentence(s.copyWith(usageCount: s.usageCount + 1));
        _history = _repo.getSentenceHistory();
        notifyListeners();
        return;
      }
    }
    await _repo.saveSentence(SentenceHistory(
      id: _repo.local.newId(),
      childId: childId,
      words: words,
      spokenText: spoken,
      createdAt: DateTime.now(),
      usageCount: 1,
    ));
    _history = _repo.getSentenceHistory();
    notifyListeners();
  }

  Future<void> toggleSentenceFavorite(SentenceHistory s) async {
    await _repo.saveSentence(s.copyWith(isFavorite: !s.isFavorite));
    _history = _repo.getSentenceHistory();
    notifyListeners();
  }
}
