/// Roles in Lumora with role-based permission helpers.
library;

enum UserRole { child, parent, caregiver, teacher, therapist, administrator }

/// Capabilities that roles can hold. Used for role-based access control.
enum Permission {
  viewChildData,
  editChildData,
  manageContent,
  manageRoutines,
  viewReports,
  manageSafety,
  manageContacts,
  inviteUsers,
  managePermissions,
  childInteract,
}

extension UserRoleX on UserRole {
  String get nameId {
    switch (this) {
      case UserRole.child:
        return 'child';
      case UserRole.parent:
        return 'parent';
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.therapist:
        return 'therapist';
      case UserRole.administrator:
        return 'administrator';
    }
  }

  /// Localization key, e.g. `role.parent`.
  String get l10nKey => 'role.$nameId';

  /// Default capability set per role. Parents/administrators hold full
  /// control; teacher/therapist are read-mostly; child interacts only.
  Set<Permission> get defaultPermissions {
    switch (this) {
      case UserRole.child:
        return const <Permission>{Permission.childInteract};
      case UserRole.parent:
      case UserRole.administrator:
        return Permission.values.toSet();
      case UserRole.caregiver:
        return const <Permission>{
          Permission.viewChildData,
          Permission.editChildData,
          Permission.manageRoutines,
          Permission.childInteract,
          Permission.viewReports,
          Permission.manageSafety,
          Permission.manageContacts,
        };
      case UserRole.teacher:
        return const <Permission>{
          Permission.viewChildData,
          Permission.viewReports,
          Permission.childInteract,
        };
      case UserRole.therapist:
        return const <Permission>{
          Permission.viewChildData,
          Permission.viewReports,
          Permission.childInteract,
          Permission.editChildData,
        };
    }
  }
}

/// Parses a role from its string id.
UserRole roleFromId(String id) {
  for (final UserRole r in UserRole.values) {
    if (r.nameId == id) return r;
  }
  return UserRole.child;
}
