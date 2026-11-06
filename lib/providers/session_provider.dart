import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../data/firebase/firebase_data_source.dart' show AuthResult, FirebaseDataSource;
import '../models/barrel.dart';
import '../repositories/lumora_repository.dart';
import 'settings_provider.dart';

/// Session state: who is using the app, which child is active, and what the
/// current role may do. Works fully offline via demo/local data.
class SessionProvider extends ChangeNotifier {
  SessionProvider(this._settings);

  final SettingsProvider _settings;

  UserModel? _user;
  ChildProfile? _child;
  UserRole _role = UserRole.child;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  ChildProfile? get child => _child;
  UserRole get role => _role;
  bool get loading => _loading;
  String? get error => _error;

  bool get isDemo => AppConfig.dataMode == DataMode.demo || (_user?.demo ?? true);

  bool get isParent => _role == UserRole.parent || _role == UserRole.administrator;
  bool get isChild => _role == UserRole.child;
  bool get isCollaborator =>
      _role == UserRole.teacher || _role == UserRole.therapist;

  /// Where this role belongs after signing in or restoring a session.
  ///
  /// Child Mode: only the child role opens Child Mode.
  /// Admin Dashboard: the administrator lands here to manage users and the org.
  /// Therapist Dashboard: therapists see assigned children and progress.
  /// Caregiver Dashboard: caregivers manage daily care, medical info and SOS.
  /// Parent Dashboard: the parent and any role that still routes here.
  String get homeRoute {
    switch (_role) {
      case UserRole.child:
        return '/child-home';
      case UserRole.administrator:
        return '/admin-dashboard';
      case UserRole.therapist:
        return '/therapist-dashboard';
      case UserRole.caregiver:
        return '/caregiver-dashboard';
      case UserRole.parent:
      case UserRole.teacher:
        return '/parent-dashboard';
    }
  }

  bool can(Permission p) => _role.defaultPermissions.contains(p);

  /// Restores the persisted session (if any) after repository init. Called
  /// once from main() — the user stays signed in until they sign out.
  Future<void> restoreSession() async {
    final String? raw = _settings.settings.signedInUserJson;
    if (raw == null || raw.isEmpty) return;
    try {
      final UserModel user =
          UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final LumoraRepository repo = LumoraRepository.instance;
      await repo.init();
      // Prefer the stored record if it still exists (keeps data fresh).
      UserModel? found;
      for (final UserModel u in repo.getUsers()) {
        if (u.id == user.id || u.email == user.email) found = u;
      }
      _user = found ?? user;
      _role = _user!.role;
      final List<ChildProfile> children = repo.getChildren();
      _child = children.isNotEmpty ? children.first : null;
      final String lastChild = _settings.settings.lastChildId;
      if (lastChild.isNotEmpty) {
        final ChildProfile? saved = repo.getChild(lastChild);
        if (saved != null) _child = saved;
      }
      notifyListeners();
    } on Exception {
      // Corrupt stored session: ignore and treat as signed out.
    }
  }

  /// Children visible to the current role. Collaborators only see children
  /// they are explicitly shared with.
  List<ChildProfile> visibleChildren() {
    final LumoraRepository repo = LumoraRepository.instance;
    if (isParent || _role == UserRole.caregiver) {
      return repo.getChildren();
    }
    if (isCollaborator) {
      return repo
          .getPermissions()
          .where((CaregiverPermission p) =>
              p.isActive &&
              p.invitedUserId == (_user?.id ?? '') &&
              p.role == _role)
          .map((CaregiverPermission p) => repo.getChild(p.childId))
          .whereType<ChildProfile>()
          .toList();
    }
    // Child role sees the active child only.
    return _child != null ? <ChildProfile>[_child!] : <ChildProfile>[];
  }

  /// Enters Demo Mode with the fictional sample family.
  Future<void> startDemo({UserRole role = UserRole.child}) async {
    _loading = true;
    notifyListeners();
    final LumoraRepository repo = LumoraRepository.instance;
    await repo.init();
    final List<ChildProfile> children = repo.getChildren();
    _child = children.isNotEmpty
        ? children.first
        : const ChildProfile(id: 'demo-child-1', name: 'Arun');
    _user = switch (role) {
      UserRole.parent => _findUser('parent@demo.lumora', repo),
      UserRole.teacher => _findUser('teacher@demo.lumora', repo),
      UserRole.therapist => _findUser('therapist@demo.lumora', repo),
      UserRole.caregiver => _findUser('caregiver@demo.lumora', repo),
      _ => UserModel(
          id: 'demo-user-child',
          name: _child!.name,
          email: '',
          role: UserRole.child,
          demo: true,
        ),
    };
    _role = role;
    // Demo entry is a real session too: persisted (and awaited) before the
    // caller navigates, so a restart straight after entering cannot lose it.
    await _settings.setSignedInUser(_user!);
    await _settings.setLastRole(role.nameId);
    await _settings.setLastChild(_child!.id);
    _loading = false;
    notifyListeners();
  }

  UserModel _findUser(String email, LumoraRepository repo) {
    for (final UserModel u in repo.getUsers()) {
      if (u.email == email) return u;
    }
    return UserModel(
      id: email,
      name: email,
      email: email,
      role: UserRole.parent,
      demo: true,
    );
  }

  /// Sign-in path. In Demo Mode (no Firebase) any of the documented demo
  /// emails with any password works locally; Firebase mode uses real auth.
  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final LumoraRepository repo = LumoraRepository.instance;
    await repo.init();

    if (AppConfig.isFirebaseAvailable) {
      final AuthResult result =
          await FirebaseDataSourceHolder.firebase.signIn(email, password);
      if (!result.success) {
        _error = result.errorKey;
        _loading = false;
        notifyListeners();
        return false;
      }
    }

    final UserModel? found = _matchDemoUser(email, repo);
    if (found == null) {
      _error = 'auth.loginFailed';
      _loading = false;
      notifyListeners();
      return false;
    }
    _user = found;
    _role = found.role;
    final List<ChildProfile> children = repo.getChildren();
    _child = children.isNotEmpty ? children.first : null;
    // Persist the session so the user stays signed in across restarts
    // until they explicitly sign out. Awaited: the write must be on disk
    // before the caller navigates away.
    await _settings.setSignedInUser(found);
    await _settings.setLastRole(_role.nameId);
    if (_child != null) await _settings.setLastChild(_child!.id);
    _loading = false;
    notifyListeners();
    return true;
  }

  UserModel? _matchDemoUser(String email, LumoraRepository repo) {
    for (final UserModel u in repo.getUsers()) {
      if (u.email.toLowerCase() == email.trim().toLowerCase()) return u;
    }
    return null;
  }

  /// Signs out: clears the in-memory session and forgets the persisted one,
  /// so the next start shows Sign in again. Awaited by callers so the stored
  /// session cannot outlive the sign-out.
  Future<void> signOut() async {
    _user = null;
    _child = null;
    _role = UserRole.child;
    notifyListeners();
    await _settings.clearSignedInUser();
  }

  /// Switches the active child profile.
  Future<void> setChild(ChildProfile child) async {
    _child = child;
    await _settings.setLastChild(child.id);
    notifyListeners();
  }

  /// Switches role (allowed for demo and role picker flows).
  Future<void> setRole(UserRole role) async {
    _role = role;
    await _settings.setLastRole(role.nameId);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Indirection so the repository layer stays framework-free while the
/// session provider can reach Firebase auth.
class FirebaseDataSourceHolder {
  static FirebaseDataSourceLike get firebase => _FirebaseAdapter();
}

abstract class FirebaseDataSourceLike {
  Future<AuthResult> signIn(String email, String password);
  Future<AuthResult> register(String email, String password);
}

class _FirebaseAdapter implements FirebaseDataSourceLike {
  @override
  Future<AuthResult> signIn(String email, String password) =>
      FirebaseDataSource.instance.signIn(email, password);

  @override
  Future<AuthResult> register(String email, String password) =>
      FirebaseDataSource.instance.register(email, password);
}
