/// Decouples provider/UI code from the flutter_tts plugin.
///
/// [bind] is called once from the app root so any layer can request speech
/// without importing plugin packages directly (keeps the services layer
/// swappable and the widget tree testable).
class TtsBridge {
  TtsBridge._();

  static Future<void> Function(String text)? _speak;
  static Future<void> Function()? _stop;

  static bool get isBound => _speak != null;

  static void bind({
    required Future<void> Function(String text) speak,
    required Future<void> Function() stop,
  }) {
    _speak = speak;
    _stop = stop;
  }

  static Future<void> speak(String text) async {
    final Future<void> Function(String text)? fn = _speak;
    if (fn == null) return;
    try {
      await fn(text);
    } catch (_) {
      // Speech output is always best-effort.
    }
  }

  static Future<void> stop() async {
    final Future<void> Function()? fn = _stop;
    if (fn == null) return;
    try {
      await fn();
    } catch (_) {
      // ignore
    }
  }
}
