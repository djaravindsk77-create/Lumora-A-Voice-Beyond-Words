import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Audio playback for caregiver-recorded audio and saved sounds.
/// Degrades gracefully when playback is unavailable.
class AudioPlayerService {
  AudioPlayerService._();
  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  bool available = true;

  /// Plays a local audio [path]; returns false when playback fails so the
  /// caller can fall back to TTS.
  Future<bool> play(String path) async {
    if (!available) return false;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      return true;
    } on Exception catch (e) {
      debugPrint('Audio playback failed ($e) - falling back to TTS.');
      available = false;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } on Exception {
      // ignore
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } on Exception {
      // ignore
    }
  }
}
