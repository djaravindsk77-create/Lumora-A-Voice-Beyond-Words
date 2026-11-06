import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:geolocator/geolocator.dart' show Position;

import '../models/barrel.dart';
import '../repositories/lumora_repository.dart';
import '../services/emergency/emergency_service.dart';
import '../services/emergency/siren_service.dart';
import '../services/location/location_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/speech/tts_service.dart';
import 'settings_provider.dart';

/// Safety state: trusted contacts, alerts with honest statuses, and the
/// consent-based Lost Child Mode.
class SafetyProvider extends ChangeNotifier {
  SafetyProvider(this._settings) {
    // Keep the siren banner honest: if playback stops (error or engine),
    // reflect it in state immediately.
    SirenService.instance.onPlayingChanged = (bool playing) {
      // A new emergency always brings the flashing screen back, even if the
      // previous one was hidden by the user.
      final bool wasHidden = _sirenFlashHidden;
      _sirenFlashHidden = false;
      if (_sirenOn != playing || wasHidden) {
        _sirenOn = playing;
        notifyListeners();
      }
    };
  }

  final SettingsProvider _settings;
  final LumoraRepository _repo = LumoraRepository.instance;

  List<TrustedContact> _contacts = <TrustedContact>[];
  List<SafetyAlert> _alerts = <SafetyAlert>[];
  bool _lostMode = false;
  bool _sharingLocation = false;
  bool _sirenOn = false;
  bool _sirenFlashHidden = false;
  bool _emergencyBusy = false;
  String? _emergencyNote;
  Position? _emergencyPosition;
  String? _locationNote;
  bool _alertTextCopied = false;

  List<TrustedContact> get contacts => List.unmodifiable(_contacts);
  List<TrustedContact> get activeContacts =>
      _contacts.where((TrustedContact c) => c.hasAccess).toList();
  List<SafetyAlert> get alerts => List.unmodifiable(_alerts);
  bool get lostMode => _lostMode;
  bool get sirenOn => _sirenOn;

  /// True while the user asked to hide the flashing emergency screen. The
  /// siren keeps sounding; the UI can offer to show the flash again.
  bool get sirenFlashHidden => _sirenFlashHidden;
  bool get emergencyBusy => _emergencyBusy;

  /// True only while the user explicitly turned sharing on; consent must
  /// also be recorded in settings. Always visible in the UI when true.
  bool get sharingLocation => _sharingLocation;

  String? get emergencyNote => _emergencyNote;

  /// The GPS fix that went out with the last emergency (null when there was
  /// none). Used to show the coordinates + an "Open in Maps" action.
  Position? get emergencyPosition => _emergencyPosition;

  /// Google Maps link for [emergencyPosition], or null.
  String? get emergencyLink =>
      _emergencyPosition == null ? null : LocationAttempt.mapsLinkFor(_emergencyPosition!);

  /// Human-readable coordinates for the last emergency fix.
  String? get emergencyCoordinates => _emergencyPosition == null
      ? null
      : '${_emergencyPosition!.latitude.toStringAsFixed(5)}, '
          '${_emergencyPosition!.longitude.toStringAsFixed(5)}';

  /// l10n key explaining the location result of the last emergency
  /// (attached / why it is missing).
  String? get locationNote => _locationNote;

  /// True when the alert text (with the map link) was copied to the
  /// clipboard, so it can be pasted if the SMS app did not open.
  bool get alertTextCopied => _alertTextCopied;

  /// Opens the OS app-settings page (used when location permission was
  /// permanently denied).
  Future<bool> openLocationSettings() =>
      EmergencyService.instance.openAppSettings();

  /// Opens the map link of the last emergency fix.
  Future<bool> openMapLink(String url) =>
      EmergencyService.instance.openMaps(url);

  /// Stops the siren if it is playing. Also restores the flashing screen so
  /// the next emergency starts with it visible.
  Future<void> stopSiren() async {
    if (_sirenFlashHidden) {
      _sirenFlashHidden = false;
      notifyListeners();
    }
    await SirenService.instance.stop();
  }

  /// Hides the flashing emergency screen while the siren keeps playing.
  void hideSirenFlash() {
    if (_sirenFlashHidden) return;
    _sirenFlashHidden = true;
    notifyListeners();
  }

  /// Shows the flashing emergency screen again after [hideSirenFlash].
  void showSirenFlash() {
    if (!_sirenFlashHidden) return;
    _sirenFlashHidden = false;
    notifyListeners();
  }

  /// The one-tap emergency action: siren on, then (best effort) location +
  /// SMS drafts to emergency contacts + stored alert + local notification.
  /// Never throws; every step degrades independently.
  Future<void> emergency({
    required String childId,
    required String childName,
    bool shareLocation = true,
  }) async {
    if (_emergencyBusy) return;
    _emergencyBusy = true;
    _emergencyNote = null;
    _locationNote = null;
    _emergencyPosition = null;
    _alertTextCopied = false;
    // A fresh emergency always shows the flashing screen again.
    _sirenFlashHidden = false;
    notifyListeners();

    // 0) Contacts must exist before we can target anyone. Reload from the
    //    repository in case this screen never got a child id.
    if (_contacts.isEmpty) {
      _contacts = _repo
          .getContacts()
          .where((TrustedContact c) => c.childId == childId)
          .toList();
      if (_contacts.isEmpty) {
        // Never silently drop an emergency: fall back to every known contact.
        _contacts = _repo.getContacts();
      }
    }

    // 1) Siren immediately - attention first, data second.
    _sirenOn = await SirenService.instance.start();
    notifyListeners();

    // 2) Location + SMS draft (consent + permission driven).
    // Always attempt to get location for emergency, even if consent was
    // previously denied, so the alert can include coordinates.
    final EmergencyService emergency = EmergencyService.instance;
    final LocationAttempt attempt = await emergency.getCurrentPosition(
      _settings.settings,
      shareLocation: true, // Always share location in emergencies
    );
    // If consent was previously off, record that we asked for it this time.
    if (attempt.failure == LocationFailure.noConsent && shareLocation) {
      // We'll let the settings screen handle consent persistence;
      // just note that location was not available this time.
      _locationNote = 'emergency.locNoConsent';
    } else {
      _locationNote = switch (attempt.failure) {
        LocationFailure.none => 'emergency.locAttached',
        LocationFailure.noConsent => 'emergency.locNoConsent',
        LocationFailure.permissionDenied => 'emergency.locPermission',
        LocationFailure.servicesDisabled => 'emergency.locServicesOff',
        LocationFailure.timeout => 'emergency.locTimeout',
        LocationFailure.unavailable => 'emergency.locUnavailable',
      };
    }
    notifyListeners();

    final String body = emergency.buildAlertText(
      childName: childName,
      message: 'This is an automated alert from Lumora. Please check on me.',
      position: attempt.position,
    );

    // Clipboard backup: the text (map link included) can always be pasted
    // even if the SMS app never opened.
    _alertTextCopied = await _copyAlertText(body);

    final int opened = await emergency.sendToEmergencyContacts(
      contacts: _contacts,
      body: body,
    );

    final String note;
    if (_contacts.isEmpty) {
      note = 'emergency.noContacts';
    } else if (opened > 0) {
      note = attempt.hasFix
          ? 'emergency.smsWithLocation'
          : 'emergency.smsNoLocation';
    } else {
      note = 'emergency.noSmsApp';
    }

    // 3) Log the alert (fields reflect what really happened).
    await raiseAlert(
      childId: childId,
      messageKey: 'safety.emergency',
      spokenText: 'Emergency',
      demo: false,
      withLocation: attempt.hasFix,
    );

    _emergencyNote = note;
    _emergencyBusy = false;
    notifyListeners();
  }

  /// Copies the alert text to the clipboard. Never throws (no clipboard on
  /// some platforms / in tests).
  Future<bool> _copyAlertText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearEmergencyNote() {
    _emergencyNote = null;
    _locationNote = null;
    _emergencyPosition = null;
    _alertTextCopied = false;
    notifyListeners();
  }

  Future<void> load(String childId) async {
    _contacts = _repo.getContacts()
        .where((TrustedContact c) => c.childId == childId)
        .toList();
    if (_contacts.isEmpty) {
      _contacts = _repo.getContacts();
    }
    _alerts = _repo.getAlerts();
    notifyListeners();
  }

  // -- alerts ----------------------------------------------------------

  /// Raises a safety alert. Displays the message, speaks it, notifies
  /// configured contacts (locally) and stores the event with an honest
  /// status. Returns the stored alert.
  Future<SafetyAlert> raiseAlert({
    required String childId,
    required String messageKey,
    required String spokenText,
    Map<String, String> params = const <String, String>{},
    bool demo = false,
    bool? withLocation,
  }) async {
    final List<TrustedContact> targets = activeContacts
        .where((TrustedContact c) =>
            c.notificationPreference != 'none' &&
            (c.isPrimary ||
                c.notificationPreference == 'all' ||
                c.relationship == 'parent' ||
                c.relationship == 'primaryCaregiver'))
        .toList();

    // Demo pipeline: notifications are queued locally. Status starts as
    // 'pending' and moves to 'sent' once local delivery is attempted.
    String status = 'pending';
    try {
      await TtsService.instance.speak(spokenText);
      await NotificationService.instance.notify(
        type: 'alert',
        title: 'Safety alert',
        body: spokenText,
        settings: _settings.settings,
        force: true,
      );
      status = 'sent';
    } catch (_) {
      // Optional services (TTS, notifications) may be missing entirely on a
      // platform: an unavailable service must never crash an alert.
      status = 'failed';
    }

    final SafetyAlert alert = SafetyAlert(
      id: _repo.local.newId(),
      childId: childId,
      messageKey: messageKey,
      messageParams: params,
      status: status,
      createdAt: DateTime.now(),
      notifiedContactIds: targets.map((TrustedContact c) => c.id).toList(),
      locationShared: withLocation ?? _sharingLocation,
      demo: demo,
    );

    await _repo.saveAlert(alert);
    _alerts = _repo.getAlerts();
    notifyListeners();
    return alert;
  }

  Future<void> acknowledgeAlert(SafetyAlert alert) async {
    await _repo.saveAlert(alert.copyWith(status: 'acknowledged'));
    _alerts = _repo.getAlerts();
    notifyListeners();
  }

  Future<void> retryAlert(SafetyAlert alert) async {
    await _repo.saveAlert(alert.copyWith(status: 'pending'));
    _alerts = _repo.getAlerts();
    notifyListeners();
  }

  Future<void> deleteAlert(SafetyAlert alert) async {
    await _repo.deleteAlert(alert.id);
    _alerts = _repo.getAlerts();
    notifyListeners();
  }

  // -- contacts --------------------------------------------------------

  Future<void> saveContact(TrustedContact c) async {
    await _repo.saveContact(c);
    _contacts = _repo.getContacts()
        .where((TrustedContact cc) => cc.childId == c.childId)
        .toList();
    notifyListeners();
  }

  Future<void> deleteContact(TrustedContact c) async {
    await _repo.deleteContact(c.id);
    _contacts = _contacts.where((TrustedContact cc) => cc.id != c.id).toList();
    notifyListeners();
  }

  Future<void> setPrimary(TrustedContact c) async {
    for (final TrustedContact other
        in _contacts.where((TrustedContact x) => x.isPrimary)) {
      if (other.id != c.id) {
        await _repo.saveContact(other.copyWith(isPrimary: false));
      }
    }
    await _repo.saveContact(c.copyWith(isPrimary: true));
    _contacts = _repo.getContacts()
        .where((TrustedContact cc) => cc.childId == c.childId)
        .toList();
    notifyListeners();
  }

  Future<void> revokeAccess(TrustedContact c) async {
    await _repo.saveContact(c.copyWith(hasAccess: false));
    _contacts = _contacts.map((TrustedContact cc) =>
        cc.id == c.id ? c.copyWith(hasAccess: false) : cc).toList();
    notifyListeners();
  }

  // -- lost child mode ---------------------------------------------------

  /// Enters Lost Child Mode. Shows the child's name + call button.
  void enterLostMode() {
    _lostMode = true;
    notifyListeners();
  }

  void exitLostMode() {
    _lostMode = false;
    stopLocationSharing();
    notifyListeners();
  }

  /// Starts consent-based location sharing; blocked without consent.
  bool startLocationSharing() {
    final bool ok =
        LocationService.instance.startSharing(_settings.settings);
    _sharingLocation = ok;
    notifyListeners();
    return ok;
  }

  void stopLocationSharing() {
    LocationService.instance.stopSharing();
    _sharingLocation = false;
    notifyListeners();
  }
}
