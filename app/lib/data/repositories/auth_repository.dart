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

  /// Sends a password-recovery email. The link lands on the app's
  /// `/reset-callback` route with a recovery session, where the user sets a new
  /// password. [redirectTo] must be in the Supabase redirect allowlist.
  Future<void> sendPasswordReset(String email, {required String redirectTo}) async {
    try {
      await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  /// Sets a new password for the currently-authenticated user. Called from the
  /// reset screen while a PASSWORD_RECOVERY session is active.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
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
