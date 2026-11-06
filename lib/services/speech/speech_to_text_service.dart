import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text wrapper. Degrades gracefully: when recognition is
/// unavailable (unsupported device, missing permission) the UI falls back
/// to text input and predefined phrases - the app stays fully functional.
class SpeechToTextService {
  SpeechToTextService._();
  static final SpeechToTextService instance = SpeechToTextService._();

  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  bool available = false;
  bool _listening = false;

  String _lastResult = '';

  Future<bool> init() async {
    if (_initialized) return available;
    _initialized = true;
    try {
      available = await _stt.initialize(
        onError: (dynamic error) => _listening = false,
        onStatus: (String status) {
          if (status == 'done' || status == 'notListening') {
            _listening = false;
          }
        },
      );
    } on Exception catch (e) {
      debugPrint('Speech-to-text unavailable ($e).');
      available = false;
    }
    return available;
  }

  bool get isListening => _listening;

  String get lastResult => _lastResult;

  /// Starts listening; results are reported through [onResult].
  Future<bool> listen({
    required void Function(String text) onResult,
    String languageCode = 'en',
  }) async {
    if (!available) return false;
    if (_listening) return true;
    try {
      _listening = true;
      _lastResult = '';
      await _stt.listen(
        onResult: (dynamic result) {
          final String text = result.recognizedWords ?? '';
          _lastResult = text;
          onResult(text);
          if (result.finalResult == true) _listening = false;
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          localeId: languageCode == 'ta' ? 'ta_IN' : 'en_US',
        ),
      );
      return true;
    } on Exception {
      _listening = false;
      return false;
    }
  }

  Future<void> stop() async {
    if (!available) return;
    try {
      await _stt.stop();
    } on Exception {
      // ignore
    }
    _listening = false;
  }
}
