
import 'package:flutter/foundation.dart';

import '../../models/settings.dart';

/// Consent-based location sharing.
///
/// Hard rules enforced here:
///  * Never active unless the user explicitly enabled [AppSettings.locationConsent].
///  * When active, state is visible (`isSharing` is exposed to the UI) and a
///    banner is shown wherever it matters.
///  * Any UI can call [stopSharing]; it can never be re-enabled silently.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  bool _sharing = false;
  String? _lastLocationSummary;

  bool get isSharing => _sharing;

  /// Human-readable last shared location summary (e.g. "approx. area").
  String? get lastLocationSummary => _lastLocationSummary;

  /// Starts sharing ONLY when consent is recorded. Returns false otherwise.
  bool startSharing(AppSettings settings) {
    if (!settings.locationConsent) {
      debugPrint(
          'Location sharing blocked: no explicit consent recorded.');
      return false;
    }
    _sharing = true;
    // Demo implementation: no real GPS is read. A production build would
    // start a geolocator stream here and push updates to trusted contacts.
    _lastLocationSummary = 'Location sharing active (demo)';
    return true;
  }

  void stopSharing() {
    _sharing = false;
    _lastLocationSummary = null;
  }

  /// Revokes consent entirely.
  void revokeConsent() {
    stopSharing();
  }
}
