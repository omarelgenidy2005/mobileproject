import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/user_role.dart';

/// Exposes auth state via [StreamProvider] in the widget tree and imperative sign-in/out.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    bool firebaseEnabled = true,
  })  : _firebaseEnabled = firebaseEnabled,
        _auth = firebaseEnabled ? (firebaseAuth ?? fb.FirebaseAuth.instance) : null,
        _firestore = firebaseEnabled ? (firestore ?? FirebaseFirestore.instance) : null;

  final bool _firebaseEnabled;
  final fb.FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoading => _isLoading;

  /// Stream consumed by [StreamProvider] for reactive auth-gated routing.
  Stream<AppUser?> authStateChanges() {
    if (!_firebaseEnabled || _auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges().asyncMap(_mapFirebaseUser);
  }

  Future<AppUser?> _mapFirebaseUser(fb.User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      notifyListeners();
      return null;
    }
    final profile = await _firestore!
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();
    _user = AppUser.fromFirebase(
      authUser: firebaseUser,
      profile: profile.data(),
    );
    notifyListeners();
    return _user;
  }

  Future<void> signIn({required String email, required String password}) async {
    if (!_firebaseEnabled || _auth == null) {
      throw const AuthException('Firebase is not configured. Run flutterfire configure.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
      await _mapFirebaseUser(_auth!.currentUser);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? displayName,
    UserRole role = UserRole.regular,
  }) async {
    if (!_firebaseEnabled || _auth == null || _firestore == null) {
      throw const AuthException('Firebase is not configured. Run flutterfire configure.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUser = AppUser(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore!
          .collection(AppConstants.usersCollection)
          .doc(newUser.id)
          .set(newUser.toFirestore());
      _user = newUser;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Registration failed.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_auth == null) return;
    await _auth!.signOut();
    _user = null;
    notifyListeners();
  }
}
