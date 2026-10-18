import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

/// Minimal auth identity surfaced to the app.
class AuthUser {
  const AuthUser({required this.id, this.email, this.name, this.avatarUrl});
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
}

/// Auth contract. Google is the primary provider (schools run Workspace);
/// email/password is the fallback.
abstract class AuthService {
  AuthUser? get currentUser;
  Stream<AuthUser?> authState();
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(String email, String password);
  Future<void> signOut();
}

/// Demo auth used when Firebase isn't configured. Starts signed out so the
/// sign-in screen is exercised; "Google" immediately signs in as the demo user.
class MockAuthService implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  static const _demoUser = AuthUser(
    id: 'mock-user',
    email: 'maya.ramirez@student.canyonsdistrict.org',
    name: 'Maya Ramirez',
  );

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authState() async* {
    yield _user;
    yield* _controller.stream;
  }

  Future<void> _signIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _user = _demoUser;
    _controller.add(_user);
  }

  @override
  Future<void> signInWithGoogle() => _signIn();

  @override
  Future<void> signInWithEmail(String email, String password) => _signIn();

  @override
  Future<void> signUpWithEmail(String email, String password) => _signIn();

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

/// Firebase-backed auth. Google works via Firebase Auth's provider flow (popup
/// on web, native provider sheet on mobile). The session is persisted by
/// firebase_auth per platform.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final fb.FirebaseAuth _auth;

  AuthUser? _map(fb.User? u) {
    if (u == null) return null;
    return AuthUser(
      id: u.uid,
      email: u.email,
      name: u.displayName,
      avatarUrl: u.photoURL,
    );
  }

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> authState() async* {
    yield currentUser;
    yield* _auth.authStateChanges().map(_map);
  }

  @override
  Future<void> signInWithGoogle() async {
    final provider = fb.GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
