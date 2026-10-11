import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/config/app_config.dart';

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

/// Demo auth used when Supabase isn't configured. Starts signed out so the
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

/// Supabase-backed auth. Google OAuth works uniformly across platforms via the
/// Supabase-hosted redirect; the session is persisted by supabase_flutter in
/// each platform's secure store.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);
  final sb.SupabaseClient _client;

  AuthUser? _map(sb.User? u) {
    if (u == null) return null;
    final meta = u.userMetadata ?? const {};
    return AuthUser(
      id: u.id,
      email: u.email,
      name: (meta['full_name'] ?? meta['name'])?.toString(),
      avatarUrl: (meta['avatar_url'] ?? meta['picture'])?.toString(),
    );
  }

  @override
  AuthUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Stream<AuthUser?> authState() async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map((e) => _map(e.session?.user));
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: kIsWeb ? null : AppConfig.authRedirectScheme,
    );
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
