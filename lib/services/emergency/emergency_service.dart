import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../models/barrel.dart';

/// Why a location could not be attached to an alert. Surfaced in the UI so the
/// user is told exactly what to fix instead of silently losing the location.
enum LocationFailure {
  /// A fix was obtained.
  none,

  /// The user has no location consent recorded (or opted out for this alert).
  noConsent,

  /// Android/iOS location permission was denied.
  permissionDenied,

  /// GPS / location services are switched off at the OS level.
  servicesDisabled,

  /// No fix arrived before the GPS timeout.
  timeout,

  /// Geolocation is unavailable on this platform (e.g. desktop).
  unavailable,
}

/// Outcome of one location attempt: the position (if any) plus the reason when
/// there is none.
@immutable
class LocationAttempt {
  const LocationAttempt(this.position, this.failure);

  const LocationAttempt.ok(Position this.position) : failure = LocationFailure.none;

  final Position? position;
  final LocationFailure failure;

  bool get hasFix => position != null;

  /// Google Maps link for the fix, or null when there is none.
  String? get mapsLink => position == null ? null : mapsLinkFor(position!);

  static String mapsLinkFor(Position p) =>
      'https://maps.google.com/?q=${p.latitude.toStringAsFixed(6)},'
      '${p.longitude.toStringAsFixed(6)}';

  /// Coordinates rounded for display, e.g. `13.0827, 80.2707`.
  String? get coordinates => position == null
      ? null
      : '${position!.latitude.toStringAsFixed(5)}, '
          '${position!.longitude.toStringAsFixed(5)}';
}

/// One-tap emergency dispatch: reads the device location and opens the SMS app
/// pre-filled with the alert text + map link for every emergency contact.
///
/// Honest boundaries (demo project):
///  * The siren is a local looping sound — it attracts attention nearby.
///  * SMS sending is handed to the phone's own messaging app (the user presses
///    send), so no server or paid gateway is required and nothing is faked.
///  * Without consent/permission/service the alert still goes out, and the UI
///    says plainly that the location is missing and why.
class EmergencyService {
  EmergencyService._();
  static final EmergencyService instance = EmergencyService._();

  /// How long to wait for a fresh GPS fix before falling back.
  static const Duration gpsTimeout = Duration(seconds: 20);

  /// Result summary for the UI.
  EmergencyOutcome? lastOutcome;

  /// Last location attempt, so screens can report the reason for a missing fix.
  LocationAttempt? lastLocationAttempt;

  /// Requests location permission and resolves the current position.
  ///
  /// Order of attempts:
  ///  1. A fresh high-accuracy fix.
  ///  2. A fresh medium-accuracy fix (faster, better indoors).
  ///  3. The last known position — so a cold GPS still yields coordinates.
  Future<LocationAttempt> getCurrentPosition(
    AppSettings settings, {
    bool shareLocation = true,
  }) async {
    LocationAttempt result = const LocationAttempt(null, LocationFailure.none);

    if (!settings.locationConsent) {
      result = const LocationAttempt(null, LocationFailure.noConsent);
      lastLocationAttempt = result;
      return result;
    }

    if (!shareLocation) {
      result = const LocationAttempt(null, LocationFailure.noConsent);
      lastLocationAttempt = result;
      return result;
    }

    try {
      final ph.PermissionStatus current =
          await ph.Permission.locationWhenInUse.status;
      if (!(current.isGranted || current.isLimited)) {
        final ph.PermissionStatus asked =
            await ph.Permission.locationWhenInUse.request();
        if (!(asked.isGranted || asked.isLimited)) {
          result = const LocationAttempt(null, LocationFailure.permissionDenied);
          lastLocationAttempt = result;
          return result;
        }
      }
    } catch (e) {
      // permission_handler is not available (web/desktop): try geolocator
      // anyway rather than giving up on the location entirely.
      debugPrint('Location permission check unavailable ($e).');
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        result =
            const LocationAttempt(null, LocationFailure.servicesDisabled);
        lastLocationAttempt = result;
        return result;
      }
    } catch (e) {
      debugPrint('Location service check failed ($e).');
    }

    // 1) Fresh fix, high accuracy.
    final Position? high = await _tryFix(
      const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (high != null) {
      result = LocationAttempt.ok(high);
      lastLocationAttempt = result;
      return result;
    }

    // 2) Fresh fix, medium accuracy (usually much faster indoors).
    final Position? medium = await _tryFix(
      const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    if (medium != null) {
      result = LocationAttempt.ok(medium);
      lastLocationAttempt = result;
      return result;
    }

    // 3) Last known position: stale coordinates still locate the child.
    final Position? last = await _lastKnown();
    if (last != null) {
      result = LocationAttempt.ok(last);
      lastLocationAttempt = result;
      return result;
    }

    result = const LocationAttempt(null, LocationFailure.timeout);
    lastLocationAttempt = result;
    return result;
  }

  Future<Position?> _tryFix(LocationSettings settings) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(gpsTimeout);
    } catch (e) {
      debugPrint('GPS fix failed ($e).');
      return null;
    }
  }

  Future<Position?> _lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('Last known position unavailable ($e).');
      return null;
    }
  }

  /// Opens the OS settings page so the user can grant a denied permission.
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      debugPrint('Could not open app settings ($e).');
      return false;
    }
  }

  /// Builds the alert text. The map link comes first so it survives SMS
  /// length trimming and is readable at a glance.
  String buildAlertText({
    required String childName,
    required String message,
    Position? position,
  }) {
    final StringBuffer buf = StringBuffer('EMERGENCY — $childName needs help. ');
    if (position != null) {
      buf.write('Location: ${LocationAttempt.mapsLinkFor(position)} . ');
    }
    buf.write(message);
    return buf.toString();
  }

  /// Emergency targets, most important first: primary first, then dedicated
  /// emergency contacts, then every other reachable contact.
  List<TrustedContact> emergencyTargets(List<TrustedContact> contacts) {
    final List<TrustedContact> reachable = contacts
        .where((TrustedContact c) => c.hasAccess && c.phone.trim().isNotEmpty)
        .toList();

    final List<TrustedContact> priority = reachable
        .where((TrustedContact c) =>
            c.isPrimary ||
            c.relationship == 'emergency' ||
            c.relationship == 'parent')
        .toList();

    if (priority.isEmpty) return reachable;

    // Keep the priority contacts first, then anyone else reachable.
    final List<TrustedContact> rest = reachable
        .where((TrustedContact c) => !priority.contains(c))
        .toList();
    return <TrustedContact>[...priority, ...rest];
  }

  /// Composes the alert SMS via the phone's SMS app.
  ///
  /// Every emergency target is included as a recipient so the single draft —
  /// with the location link — reaches all of them at once. If the SMS app
  /// refuses a multi-recipient URI, each contact is retried individually.
  /// Returns the number of recipients reached.
  Future<int> sendToEmergencyContacts({
    required List<TrustedContact> contacts,
    required String body,
  }) async {
    final List<TrustedContact> targets = emergencyTargets(contacts);
    final bool withLocation = body.contains('https://maps.google.com');

    if (targets.isEmpty) {
      lastOutcome = const EmergencyOutcome(
        contactCount: 0,
        openedCount: 0,
        withLocation: false,
      );
      return 0;
    }

    final List<String> numbers = targets
        .map((TrustedContact c) => c.phone.replaceAll(RegExp(r'[^\d+]'), ''))
        .where((String n) => n.isNotEmpty)
        .toList();

    if (numbers.isEmpty) {
      lastOutcome = EmergencyOutcome(
        contactCount: targets.length,
        openedCount: 0,
        withLocation: withLocation,
      );
      return 0;
    }

    // Preferred: one draft addressed to every contact.
    if (await _openSms(numbers, body)) {
      lastOutcome = EmergencyOutcome(
        contactCount: targets.length,
        openedCount: targets.length,
        withLocation: withLocation,
      );
      return targets.length;
    }

    // Fallback: some SMS apps reject comma-separated recipients.
    int opened = 0;
    for (final String number in numbers) {
      if (await _openSms(<String>[number], body)) opened++;
    }

    lastOutcome = EmergencyOutcome(
      contactCount: targets.length,
      openedCount: opened,
      withLocation: withLocation,
    );
    return opened;
  }

  Future<bool> _openSms(List<String> numbers, String body) async {
    try {
      final Uri uri = Uri(
        scheme: 'sms',
        path: numbers.join(','),
        queryParameters: <String, String>{'body': body},
      );
      return await launchUri(uri);
    } catch (e) {
      debugPrint('SMS compose failed for ${numbers.join(",")} ($e).');
      return false;
    }
  }

  /// Opens the dialer for a contact so the child/caregiver can call directly.
  Future<bool> dial(String phone) async {
    try {
      return await launchUri(Uri(scheme: 'tel', path: phone));
    } catch (e) {
      debugPrint('Dial failed for $phone ($e).');
      return false;
    }
  }

  /// Opens a map link (used to show the shared emergency location).
  Future<bool> openMaps(String url) async {
    try {
      return await launchUri(Uri.parse(url));
    } catch (e) {
      debugPrint('Could not open map link ($e).');
      return false;
    }
  }

  /// Indirection so tests can stub launcher calls.
  Future<bool> launchUri(Uri uri) async {
    return launcher.launchUrl(
      uri,
      mode: launcher.LaunchMode.externalApplication,
    );
  }
}

/// Summary of what the emergency dispatch actually did.
class EmergencyOutcome {
  const EmergencyOutcome({
    required this.contactCount,
    required this.openedCount,
    required this.withLocation,
  });

  final int contactCount;
  final int openedCount;
  final bool withLocation;

  bool get hasContacts => contactCount > 0;
}
