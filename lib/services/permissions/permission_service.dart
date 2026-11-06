import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime permission handling. All requests are consent-driven and the app
/// always continues with a fallback when a permission is denied.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  Future<bool> requestMicrophone() => _request(Permission.microphone);

  Future<bool> requestNotifications() => _request(Permission.notification);

  Future<bool> requestPhotos() async {
    // Photos are used for custom cards / artwork (consent-driven).
    return _request(Permission.photos);
  }

  Future<bool> _request(Permission p) async {
    try {
      final PermissionStatus status = await p.request();
      return status.isGranted || status.isLimited;
    } on Exception catch (e) {
      debugPrint('Permission ${p.toString()} failed ($e).');
      return false;
    }
  }

  Future<bool> check(Permission p) async {
    try {
      return await p.isGranted;
    } on Exception {
      return false;
    }
  }
}
