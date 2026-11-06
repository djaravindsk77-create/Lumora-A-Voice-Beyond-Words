import 'package:flutter/foundation.dart';

import 'user_role.dart';

/// A Lumora account user (parent, teacher, therapist, etc.).
@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarKey = 'guardian',
    this.demo = false,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatarKey;

  /// True for fictional demo accounts.
  final bool demo;

  UserModel copyWith({String? name, UserRole? role, String? avatarKey}) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        role: role ?? this.role,
        avatarKey: avatarKey ?? this.avatarKey,
        demo: demo,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'role': role.nameId,
        'avatarKey': avatarKey,
        'demo': demo,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: roleFromId(json['role'] as String? ?? 'parent'),
        avatarKey: json['avatarKey'] as String? ?? 'guardian',
        demo: json['demo'] as bool? ?? false,
      );
}

/// Permissions a parent has granted to a collaborator (caregiver, teacher,
/// therapist). Shared data is explicit and revocable.
@immutable
class CaregiverPermission {
  const CaregiverPermission({
    required this.id,
    required this.childId,
    required this.invitedUserId,
    required this.invitedUserName,
    required this.role,
    required this.canViewReports,
    required this.canViewEmotions,
    required this.canViewRoutines,
    required this.canAssignActivities,
    required this.canWriteNotes,
    required this.canReceiveAlerts,
    this.status = 'active',
    this.inviteCode,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String invitedUserId;
  final String invitedUserName;
  final UserRole role;

  // Granular sharing switches (parent-controlled).
  final bool canViewReports;
  final bool canViewEmotions;
  final bool canViewRoutines;
  final bool canAssignActivities;
  final bool canWriteNotes;
  final bool canReceiveAlerts;

  /// active | pending | revoked
  final String status;
  final String? inviteCode;
  final DateTime? createdAt;

  bool get isRevoked => status == 'revoked';
  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  CaregiverPermission copyWith({
    bool? canViewReports,
    bool? canViewEmotions,
    bool? canViewRoutines,
    bool? canAssignActivities,
    bool? canWriteNotes,
    bool? canReceiveAlerts,
    String? status,
    String? inviteCode,
  }) =>
      CaregiverPermission(
        id: id,
        childId: childId,
        invitedUserId: invitedUserId,
        invitedUserName: invitedUserName,
        role: role,
        canViewReports: canViewReports ?? this.canViewReports,
        canViewEmotions: canViewEmotions ?? this.canViewEmotions,
        canViewRoutines: canViewRoutines ?? this.canViewRoutines,
        canAssignActivities: canAssignActivities ?? this.canAssignActivities,
        canWriteNotes: canWriteNotes ?? this.canWriteNotes,
        canReceiveAlerts: canReceiveAlerts ?? this.canReceiveAlerts,
        status: status ?? this.status,
        inviteCode: inviteCode ?? this.inviteCode,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'childId': childId,
        'invitedUserId': invitedUserId,
        'invitedUserName': invitedUserName,
        'role': role.nameId,
        'canViewReports': canViewReports,
        'canViewEmotions': canViewEmotions,
        'canViewRoutines': canViewRoutines,
        'canAssignActivities': canAssignActivities,
        'canWriteNotes': canWriteNotes,
        'canReceiveAlerts': canReceiveAlerts,
        'status': status,
        'inviteCode': inviteCode,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory CaregiverPermission.fromJson(Map<String, dynamic> json) =>
      CaregiverPermission(
        id: json['id'] as String,
        childId: json['childId'] as String,
        invitedUserId: json['invitedUserId'] as String? ?? '',
        invitedUserName: json['invitedUserName'] as String? ?? '',
        role: roleFromId(json['role'] as String? ?? 'teacher'),
        canViewReports: json['canViewReports'] as bool? ?? true,
        canViewEmotions: json['canViewEmotions'] as bool? ?? false,
        canViewRoutines: json['canViewRoutines'] as bool? ?? false,
        canAssignActivities: json['canAssignActivities'] as bool? ?? false,
        canWriteNotes: json['canWriteNotes'] as bool? ?? true,
        canReceiveAlerts: json['canReceiveAlerts'] as bool? ?? false,
        status: json['status'] as String? ?? 'active',
        inviteCode: json['inviteCode'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );
}
