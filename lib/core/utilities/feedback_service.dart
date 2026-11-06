import 'package:flutter/services.dart';

/// Centralised haptics/sound feedback that respects the user's
/// accessibility preferences. All methods are safe no-ops when feedback
/// is disabled, so UI code can call them unconditionally.
class FeedbackService {
  FeedbackService._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Light tap for successful interactions (card selected, step done).
  static void tap() {
    if (!hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact for confirmations (routine completed, alert sent).
  static void confirm() {
    if (!hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Warning feedback for errors (never aggressive).
  static void error() {
    if (!hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Plays a short system click sound when sound is enabled. Uses
  /// [SystemSound.play] so no audio assets are required.
  static void click() {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  /// Combined positive feedback: click + light tap.
  static void success() {
    click();
    tap();
  }
}
