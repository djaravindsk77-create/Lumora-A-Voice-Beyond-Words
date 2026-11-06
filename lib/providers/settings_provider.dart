import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart' show ContrastChoice, ThemeChoice;
import '../core/utilities/feedback_service.dart';
import '../models/barrel.dart';

/// App-wide settings & accessibility state.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs);

  final SharedPreferences _prefs;
  AppSettings _settings = const AppSettings();
  AccessibilitySettings _accessibility = const AccessibilitySettings();
  String _version = '';

  AppSettings get settings => _settings;
  AccessibilitySettings get accessibility => _accessibility;
  String get version => _version;

  Locale get locale => Locale(_settings.languageCode);

  ThemeChoice get themeChoice {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeChoice.light;
      case 'dark':
        return ThemeChoice.dark;
      default:
        return ThemeChoice.system;
    }
  }

  ContrastChoice get contrastChoice => _accessibility.highContrast
      ? ContrastChoice.high
      : ContrastChoice.normal;

  // ------------------------------------------------------------------
  // Load / persist
  // ------------------------------------------------------------------

  Future<void> load() async {
    final String? raw = _prefs.getString('lumora.settings');
    if (raw != null) {
      try {
        _settings =
            AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        _settings = const AppSettings();
      }
    }
    final String? aRaw = _prefs.getString('lumora.accessibility');
    if (aRaw != null) {
      try {
        _accessibility = AccessibilitySettings.fromJson(
            jsonDecode(aRaw) as Map<String, dynamic>);
      } on FormatException {
        _accessibility = const AccessibilitySettings();
      }
    }
    FeedbackService.soundEnabled = _accessibility.soundEnabled;
    FeedbackService.hapticsEnabled = _accessibility.hapticsEnabled;
    // Bounded and failure-proof: the version label is cosmetic, and an absent
    // or slow plugin must never stall settings loading (it previously hung
    // forever where the platform channel had no responder, e.g. in tests).
    try {
      final PackageInfo info = await PackageInfo.fromPlatform()
          .timeout(const Duration(seconds: 2));
      _version = info.version;
    } catch (_) {
      _version = '';
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs.setString(
        'lumora.settings', jsonEncode(_settings.toJson()));
    await _prefs.setString(
        'lumora.accessibility', jsonEncode(_accessibility.toJson()));
  }

  // ------------------------------------------------------------------
  // Mutations
  // ------------------------------------------------------------------

  Future<void> setLanguage(String code) async {
    _settings = _settings.copyWith(languageCode: code);
    await _persist();
    notifyListeners();
  }

  Future<void> setThemeChoice(ThemeChoice choice) async {
    _settings = _settings.copyWith(themeMode: choice.name);
    await _persist();
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool done) async {
    _settings = _settings.copyWith(onboardingComplete: done);
    await _persist();
    notifyListeners();
  }

  Future<void> setLastRole(String role) async {
    _settings = _settings.copyWith(lastRole: role);
    await _persist();
    notifyListeners();
  }

  Future<void> setLastChild(String childId) async {
    _settings = _settings.copyWith(lastChildId: childId);
    await _persist();
    notifyListeners();
  }

  /// Persists the signed-in user (session survives restarts until sign out).
  Future<void> setSignedInUser(UserModel user) async {
    _settings = _settings.copyWith(signedInUserJson: jsonEncode(user.toJson()));
    await _persist();
    notifyListeners();
  }

  /// Clears the stored session (keeps every other setting intact).
  /// Called only from the Sign out action.
  Future<void> clearSignedInUser() async {
    _settings =
        _settings.copyWith(signedInUserJson: null); // sentinel-aware clear
    await _persist();
    notifyListeners();
  }

  // -- accessibility -------------------------------------------------

  Future<void> updateAccessibility(AccessibilitySettings a) async {
    _accessibility = a;
    FeedbackService.soundEnabled = a.soundEnabled;
    FeedbackService.hapticsEnabled = a.hapticsEnabled;
    await _persist();
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    // Update the in-memory value immediately so any read gets the latest,
    // but only rebuild listeners when the user has stopped dragging the slider.
    // Eager notification during active slider dragging can conflict with the
    // slider's own layout pass and paint the yellow/black debug stripes.
    _accessibility = _accessibility.copyWith(textScale: scale);
    FeedbackService.soundEnabled = _accessibility.soundEnabled;
    FeedbackService.hapticsEnabled = _accessibility.hapticsEnabled;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleHighContrast() =>
      updateAccessibility(_accessibility.copyWith(
          highContrast: !_accessibility.highContrast));

  Future<void> toggleReducedMotion() =>
      updateAccessibility(_accessibility.copyWith(
          reducedMotion: !_accessibility.reducedMotion));

  Future<void> toggleSound() => updateAccessibility(
      _accessibility.copyWith(soundEnabled: !_accessibility.soundEnabled));

  Future<void> toggleHaptics() => updateAccessibility(_accessibility
      .copyWith(hapticsEnabled: !_accessibility.hapticsEnabled));

  Future<void> toggleLargeButtons() =>
      updateAccessibility(_accessibility.copyWith(
          largeButtons: !_accessibility.largeButtons));

  Future<void> resetAccessibility() =>
      updateAccessibility(const AccessibilitySettings());

  // -- notifications ---------------------------------------------------

  Future<void> updateNotifPref(String key, bool value) async {
    switch (key) {
      case 'routine':
        _settings = _settings.copyWith(notifRoutine: value);
        break;
      case 'activity':
        _settings = _settings.copyWith(notifActivity: value);
        break;
      case 'alert':
        _settings = _settings.copyWith(notifAlerts: value);
        break;
      case 'assigned':
        _settings = _settings.copyWith(notifAssigned: value);
        break;
      case 'notes':
        _settings = _settings.copyWith(notifNotes: value);
        break;
      case 'events':
        _settings = _settings.copyWith(notifEvents: value);
        break;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setQuietHours({
    required bool enabled,
    required int startMinutes,
    required int endMinutes,
  }) async {
    _settings = _settings.copyWith(
      quietHoursEnabled: enabled,
      quietStartMinutes: startMinutes,
      quietEndMinutes: endMinutes,
    );
    await _persist();
    notifyListeners();
  }

  // -- privacy / consent ---------------------------------------------

  Future<void> setTrackingEnabled(bool v) async {
    _settings = _settings.copyWith(trackingEnabled: v);
    await _persist();
    notifyListeners();
  }

  Future<void> setLocationConsent(bool v) async {
    _settings = _settings.copyWith(locationConsent: v);
    if (!v) {
      // Silently-disableable location: revoking consent stops sharing.
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setMicConsent(bool v) async {
    _settings = _settings.copyWith(micConsent: v);
    await _persist();
    notifyListeners();
  }

  Future<void> setPhotoConsent(bool v) async {
    _settings = _settings.copyWith(photoConsent: v);
    await _persist();
    notifyListeners();
  }

  Future<void> setModeSuggestions(bool v) async {
    _settings = _settings.copyWith(modeSuggestionsEnabled: v);
    await _persist();
    notifyListeners();
  }

  Future<void> setDefaultMode(String id) async {
    _settings = _settings.copyWith(defaultModeId: id);
    await _persist();
    notifyListeners();
  }
}
