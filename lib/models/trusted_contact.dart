import 'package:flutter/foundation.dart';

/// A trusted contact configured by the parent (used by Safety and
/// Lost Child Mode). Includes permission level and notification preference.
@immutable
class TrustedContact {
  const TrustedContact({
    required this.id,
    required this.childId,
    required this.name,
    required this.relationship,
    required this.phone,
    this.email,
    this.photoPath,
    this.permissionLevel = 'viewer',
    this.notificationPreference = 'alerts',
    this.isPrimary = false,
    this.hasAccess = true,
  });

  final String id;
  final String childId;
  final String name;

  /// parent | primaryCaregiver | secondaryCaregiver | teacher | therapist |
  /// emergency
  final String relationship;
  final String phone;
  final String? email;

  /// Local file path to a profile photo (optional).
  final String? photoPath;

  /// viewer | editor | full
  final String permissionLevel;

  /// none | alerts | all
  final String notificationPreference;
  final bool isPrimary;

  /// false once access has been revoked by the parent.
  final bool hasAccess;

  TrustedContact copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? email,
    String? photoPath,
    String? permissionLevel,
    String? notificationPreference,
    bool? isPrimary,
    bool? hasAccess,
  }) =>
      TrustedContact(
        id: id,
        childId: childId,
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photoPath: photoPath ?? this.photoPath,
        permissionLevel: permissionLevel ?? this.permissionLevel,
        notificationPreference:
            notificationPreference ?? this.notificationPreference,
        isPrimary: isPrimary ?? this.isPrimary,
        hasAccess: hasAccess ?? this.hasAccess,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'photoPath': photoPath,
        'permissionLevel': permissionLevel,
        'notificationPreference': notificationPreference,
        'isPrimary': isPrimary,
        'hasAccess': hasAccess,
      };

  factory TrustedContact.fromJson(Map<String, dynamic> json) =>
      TrustedContact(
        id: json['id'] as String,
        childId: json['childId'] as String,
        name: json['name'] as String? ?? '',
        relationship: json['relationship'] as String? ?? 'parent',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
        photoPath: json['photoPath'] as String?,
        permissionLevel: json['permissionLevel'] as String? ?? 'viewer',
        notificationPreference:
            json['notificationPreference'] as String? ?? 'alerts',
        isPrimary: json['isPrimary'] as bool? ?? false,
        hasAccess: json['hasAccess'] as bool? ?? true,
      );
}

/// A safety alert event with delivery status tracking.
///
/// Statuses are honest: `sent` means the local notification pipeline queued
/// the alert - Lumora never guarantees emergency delivery.
@immutable
class SafetyAlert {
  const SafetyAlert({
    required this.id,
    required this.childId,
    required this.messageKey,
    required this.status,
    required this.createdAt,
    this.messageParams = const <String, String>{},
    this.rawMessage,
    this.notifiedContactIds = const <String>[],
    this.locationShared = false,
    this.demo = true,
  });

  final String id;
  final String childId;
  final String messageKey;
  final Map<String, String> messageParams;

  /// Raw message when the alert used free text.
  final String? rawMessage;

  /// sent | pending | failed | acknowledged
  final String status;
  final DateTime createdAt;
  final List<String> notifiedContactIds;

  /// Whether consent-based location was attached (visible when active).
  final bool locationShared;

  /// True for the explicit demo alerts.
  final bool demo;

  SafetyAlert copyWith({String? status, List<String>? notifiedContactIds}) =>
      SafetyAlert(
        id: id,
        childId: childId,
        messageKey: messageKey,
        messageParams: messageParams,
        rawMessage: rawMessage,
        status: status ?? this.status,
        createdAt: createdAt,
        notifiedContactIds: notifiedContactIds ?? this.notifiedContactIds,
        locationShared: locationShared,
        demo: demo,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'messageKey': messageKey,
        'messageParams': messageParams,
        'rawMessage': rawMessage,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'notifiedContactIds': notifiedContactIds,
        'locationShared': locationShared,
        'demo': demo,
      };

  factory SafetyAlert.fromJson(Map<String, dynamic> json) => SafetyAlert(
        id: json['id'] as String,
        childId: json['childId'] as String,
        messageKey: json['messageKey'] as String? ?? 'safety.needHelp',
        messageParams:
            (json['messageParams'] as Map<String, dynamic>? ?? const {})
                .cast<String, String>(),
        rawMessage: json['rawMessage'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        notifiedContactIds:
            (json['notifiedContactIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        locationShared: json['locationShared'] as bool? ?? false,
        demo: json['demo'] as bool? ?? true,
      );
}
