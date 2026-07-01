import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../../core/errors/failure.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUpWithEmail({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.gametensor://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  /// Required alongside Google OAuth on iOS per App Store Guideline 4.8.
  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthFailure('Apple sign-in did not return an identity token');
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(supabase);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
