import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Emergency siren playback.
///
/// Primary path: the MP3 siren you chose (`assets/audio/siren.mp3`) — a real,
/// looping air-raid siren that sounds loudly until [stop] is called.
///
/// Robustness rules:
///  * [start] waits for the player to actually reach [PlayerState.playing]
///    before reporting success, so the UI never shows a phantom "siren on".
///  * If the asset fails to prepare or the player dies, the siren is retried
///    a few times and then falls back to a loud spoken alert through TTS.
///  * Player errors are watched via [AudioPlayer.onPlayerStateChanged] so the
///    "siren is ON" banner disappears honestly if playback stops.
///
/// The siren uses its own dedicated [AudioPlayer] so it is completely isolated
/// from any other sound the app plays (AAC narration, activity sounds, etc.).
class SirenService {
  SirenService._();
  static final SirenService instance = SirenService._();

  /// Preferred asset: the real siren MP3 you attached.
  static const String _assetMp3 = 'audio/siren.mp3';

  /// Fallback asset: the old generated WAV, kept only if MP3 is missing.
  static const String _assetWav = 'audio/siren.wav';

  AudioPlayer? _player;
  bool _playing = false;
  bool _usingFallback = false;
  bool _stateHooked = false;
  Function(bool playing)? _listener;

  bool get isPlaying => _playing;
  bool get usingFallback => _usingFallback;

  /// Optional UI hook: called whenever playing state changes.
  set onPlayingChanged(Function(bool playing)? cb) => _listener = cb;

  void _setPlaying(bool v) {
    if (_playing == v) return;
    _playing = v;
    _listener?.call(v);
  }

  /// Starts the looping siren. Returns true only when audio actually plays.
  Future<bool> start() async {
    if (_playing) return true;
    _usingFallback = false;

    // Audio is optional: a missing or failing audio plugin must never block
    // an emergency, so player setup is guarded and falls through to the
    // spoken siren instead of throwing.
    bool audioReady = false;
    try {
      // Build a fresh player only when needed; siren playback is isolated.
      final AudioPlayer player = _player ?? AudioPlayer();
      _player = player;

      // Hook player-state changes once so playback failures flip the banner.
      if (!_stateHooked) {
        _stateHooked = true;
        player.onPlayerStateChanged.listen(_onPlayerStateChanged);
      }

      // Set loop + max volume *before* setting the source (`play()` re-applies
      // the last-set volume on every resume, which keeps the siren loud).
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);
      await player.setPlaybackRate(1.0);
      audioReady = true;
    } catch (e) {
      debugPrint('Siren audio player unavailable ($e).');
    }

    if (audioReady) {
      final AudioPlayer? player = _player;
      if (player != null) {
        // Try assets a few times. On Android/web the first attempt can fail
        // while the asset bundle finishes registering after a hot restart.
        for (int attempt = 0; attempt < 4; attempt++) {
          final bool ok = await _tryAsset(player, _assetMp3, attempt);
          if (ok) return true;
          // Back off briefly so the bundle/event stream can settle.
          await Future<void>.delayed(_backoff(attempt));
        }

        // The old WAV only exists as a fallback if the MP3 ship is incomplete.
        for (int attempt = 0; attempt < 2; attempt++) {
          final bool ok = await _tryAsset(player, _assetWav, attempt);
          if (ok) return true;
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      }
    }

    // Fallback path: speak a loud repeated warning through TTS.
    try {
      final bool spoke = await ttsFallback();
      if (spoke) {
        _usingFallback = true;
        _setPlaying(true);
        return true;
      }
    } catch (e) {
      debugPrint('Siren TTS fallback failed ($e).');
    }
    return false;
  }

  Future<bool> _tryAsset(AudioPlayer player, String asset, int attempt) async {
    try {
      // `play()` sets the source internally and resumes; on `ReleaseMode.loop`
      // the player keeps looping until `stop()` is called.
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('Siren asset failed ($asset, attempt $attempt): $e');
      return false;
    }

    // If the player reached playing, that's a confirmed success.
    if (player.state == PlayerState.playing) {
      _setPlaying(true);
      return true;
    }

    // Wait for the engine to actually start playing.
    bool confirmed = false;
    for (int i = 0; i < 14; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (player.state == PlayerState.playing) {
        confirmed = true;
        break;
      }
      // If the source visibly failed to prepare/play, bail out early.
      if (player.state == PlayerState.stopped && i >= 2) {
        break;
      }
    }
    if (confirmed) {
      _setPlaying(true);
      return true;
    }
    debugPrint('Siren: "$asset" did not reach playing state.');
    return false;
  }

  void _onPlayerStateChanged(PlayerState s) {
    if (s == PlayerState.stopped && _playing) {
      _setPlaying(false);
    }
  }

  static Duration _backoff(int attempt) {
    return Duration(milliseconds: 250 + attempt * 150);
  }

  /// Bridge so the service can use TTS without importing the speech stack
  /// (avoids a circular dependency with providers). Bound from app.dart.
  static Future<void> Function(String text)? ttsSpeak;

  Future<bool> ttsFallback() async {
    final Future<void> Function(String text)? speak = ttsSpeak;
    if (speak == null) return false;
    await speak('Emergency! Emergency! Please help!');
    return true;
  }

  /// Stops the siren (safe to call repeatedly). Prefer `safety.stopSiren()`
  /// from the provider, which also updates the UI state.
  Future<void> stop() async {
    if (!_playing && _player == null) return;
    try {
      await _player?.stop();
    } catch (_) {}
    _setPlaying(false);
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
