import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;

/// Simple screen-reader announcement helper.
///
/// Sends polite announcements to assistive technology on real devices
/// through Flutter's semantics service (the legacy `announce` API, kept
/// intentionally with an ignore because the replacement needs a view
/// handle); in tests it silently records the last message so assertions
/// can be made.
class AccessibilityAnnouncer {
  AccessibilityAnnouncer._();

  static final Queue<String> _history = Queue<String>();

  /// Last announced message (useful for tests and debugging).
  static String? get lastMessage => _history.isEmpty ? null : _history.last;

  /// Announces [message] politely to assistive technology.
  static void announce(BuildContext? context, String message) {
    _history.add(message);
    if (_history.length > 20) _history.removeFirst();
    if (context == null) return;
    final TextDirection? dir = Directionality.maybeOf(context);
    // ignore: deprecated_member_use
    SemanticsService.announce(message, dir ?? TextDirection.ltr);
  }

  /// Clears history (used by tests).
  static void reset() => _history.clear();
}
