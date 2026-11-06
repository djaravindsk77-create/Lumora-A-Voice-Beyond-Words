import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import 'firebase_options_stub.dart' as options_stub;

/// Result of an authentication attempt.
class AuthResult {
  const AuthResult({required this.success, this.userId, this.errorKey});
  final bool success;

  /// Localization key describing the error, when unsuccessful.
  final String? errorKey;
  final String? userId;
}

/// Firebase-backed data source.
///
/// The app must never crash because Firebase is missing/misconfigured, so
/// every call is guarded: when Firebase is unavailable the methods return
/// `null`/[AuthResult.success]=false and the caller falls back to the local
/// offline store (offline-first contract).
class FirebaseDataSource {
  FirebaseDataSource._();
  static final FirebaseDataSource instance = FirebaseDataSource._();

  bool _available = false;
  bool _triedInit = false;

  bool get isAvailable => _available;

  /// Attempts to initialise Firebase. Never throws.
  Future<bool> tryInitialize() async {
    if (_available) return true;
    if (_triedInit) return _available;
    _triedInit = true;
    try {
      final FirebaseOptions? opts = options_stub.getFirebaseOptions;
      if (opts != null) {
        await Firebase.initializeApp(options: opts);
      } else {
        // Android reads google-services.json values at build time when the
        // Gradle plugin is applied; other platforms require flutterfire.
        await Firebase.initializeApp();
      }
      _available = true;
      AppConfig.markFirebaseInitialized();
    } on Exception catch (e) {
      debugPrint('Firebase not available ($e) - continuing in Demo Mode.');
      _available = false;
    }
    return _available;
  }

  FirebaseAuth? get _auth => _available ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _db => _available ? FirebaseFirestore.instance : null;

  // ------------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------------

  Stream<User?> authState() {
    final FirebaseAuth? a = _auth;
    if (a == null) return const Stream<User?>.empty();
    return a.authStateChanges();
  }

  User? get currentUser {
    final FirebaseAuth? a = _auth;
    if (a == null) return null;
    return a.currentUser;
  }

  Future<AuthResult> signIn(String email, String password) async {
    final FirebaseAuth? a = _auth;
    if (a == null) {
      return const AuthResult(success: false, errorKey: 'auth.noFirebase');
    }
    try {
      final UserCredential cred = await a.signInWithEmailAndPassword(
          email: email, password: password);
      return AuthResult(success: true, userId: cred.user?.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
          success: false, errorKey: _mapAuthError(e.code));
    } on Exception {
      return const AuthResult(
          success: false, errorKey: 'common.unknownError');
    }
  }

  Future<AuthResult> register(String email, String password) async {
    final FirebaseAuth? a = _auth;
    if (a == null) {
      return const AuthResult(success: false, errorKey: 'auth.noFirebase');
    }
    try {
      final UserCredential cred = await a.createUserWithEmailAndPassword(
          email: email, password: password);
      return AuthResult(success: true, userId: cred.user?.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
          success: false, errorKey: _mapAuthError(e.code));
    } on Exception {
      return const AuthResult(
          success: false, errorKey: 'common.unknownError');
    }
  }

  Future<AuthResult> sendPasswordReset(String email) async {
    final FirebaseAuth? a = _auth;
    if (a == null) {
      return const AuthResult(success: false, errorKey: 'auth.noFirebase');
    }
    try {
      await a.sendPasswordResetEmail(email: email);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(
          success: false, errorKey: _mapAuthError(e.code));
    } on Exception {
      return const AuthResult(
          success: false, errorKey: 'common.unknownError');
    }
  }

  Future<void> signOut() async {
    final FirebaseAuth? a = _auth;
    if (a == null) return;
    await a.signOut();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'common.invalidEmail';
      case 'user-not-found':
      case 'wrong-password':
        return 'auth.loginFailed';
      case 'email-already-in-use':
        return 'auth.emailInUse';
      case 'weak-password':
        return 'common.passwordTooShort';
      case 'network-request-failed':
        return 'common.networkError';
      default:
        return 'common.unknownError';
    }
  }

  // ------------------------------------------------------------------
  // Firestore sync (opt-in; only when cloud sync is enabled)
  // ------------------------------------------------------------------

  /// Pushes a record to the cloud mirror of [collection]. Returns false on
  /// any failure so the offline queue can retain the operation.
  Future<bool> pushRecord(
    String collection,
    String docId,
    Map<String, dynamic> json,
  ) async {
    final FirebaseFirestore? db = _db;
    if (db == null || !AppConfig.enableCloudSync) return false;
    try {
      await db
          .collection(collection)
          .doc(docId)
          .set(json, SetOptions(merge: true));
      return true;
    } on Exception {
      return false;
    }
  }

  /// Pulls all documents of [collection] (null when unavailable).
  Future<List<Map<String, dynamic>>>? pullCollection(String collection) {
    final FirebaseFirestore? db = _db;
    if (db == null || !AppConfig.enableCloudSync) return null;
    return db.collection(collection).get().then(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => d.data())
              .toList(),
        );
  }
}
