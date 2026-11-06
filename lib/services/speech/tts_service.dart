import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech wrapper around flutter_tts.
///
/// Never throws: if the platform TTS engine is missing, [isAvailable]
/// becomes false and [speak] silently succeeds so the UI stays functional.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool isAvailable = true;
  bool _speaking = false;

  double speechRate = 0.45;
  double speechVolume = 1.0;
  double speechPitch = 1.0;
  String languageCode = 'en';

  List<Map<String, dynamic>> voices = <Map<String, dynamic>>[];
  String? selectedVoice;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dynamic langOk = await _tts.isLanguageAvailable('en-US');
      isAvailable = langOk == true;
      await _tts.awaitSpeakCompletion(true);
      await _loadVoices();
      await applyLanguage(languageCode);
      await _tts.setSpeechRate(speechRate);
      await _tts.setVolume(speechVolume);
      await _tts.setPitch(speechPitch);
    } on Exception catch (e) {
      debugPrint('TTS init failed ($e) - running without speech output.');
      isAvailable = false;
    }
  }

  Future<void> _loadVoices() async {
    try {
      final dynamic vs = await _tts.getVoices;
      if (vs is List) {
        voices = vs
            .whereType<Map>()
            .map((Map v) => v.cast<String, dynamic>())
            .toList();
      }
    } on Exception {
      voices = <Map<String, dynamic>>[];
    }
  }

  Future<void> applyLanguage(String code) async {
    languageCode = code;
    if (!isAvailable) return;
    try {
      await _tts.setLanguage(code == 'ta' ? 'ta-IN' : 'en-US');
    } on Exception {
      // Language not installed - TTS still works with default language.
    }
  }

  /// True when a Tamil-capable voice is installed on the device.
  bool get hasTamilVoice {
    for (final Map<String, dynamic> v in voices) {
      final String? locale = (v['locale'] as String?) ?? (v['name'] as String?);
      if (locale != null && locale.toLowerCase().startsWith('ta')) {
        return true;
      }
    }
    return false;
  }

  Future<void> setRate(double rate) async {
    speechRate = rate;
    if (!isAvailable) return;
    try {
      await _tts.setSpeechRate(rate);
    } on Exception {
      // ignore
    }
  }

  Future<void> setVolume(double volume) async {
    speechVolume = volume;
    if (!isAvailable) return;
    try {
      await _tts.setVolume(volume);
    } on Exception {
      // ignore
    }
  }

  Future<void> setPitch(double pitch) async {
    speechPitch = pitch;
    if (!isAvailable) return;
    try {
      await _tts.setPitch(pitch);
    } on Exception {
      // ignore
    }
  }

  Future<void> setVoice(String voiceName, String locale) async {
    selectedVoice = voiceName;
    if (!isAvailable) return;
    try {
      await _tts.setVoice(<String, String>{'name': voiceName, 'locale': locale});
    } on Exception {
      // ignore
    }
  }

  /// Speaks [text]. Completes when done (or immediately when TTS is off).
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (!isAvailable) return;
    try {
      _speaking = true;
      await _tts.speak(text);
      _speaking = false;
    } on Exception {
      _speaking = false;
    }
  }

  Future<void> stop() async {
    if (!isAvailable) return;
    try {
      await _tts.stop();
      _speaking = false;
    } on Exception {
      // ignore
    }
  }

  bool get isSpeaking => _speaking;
}
