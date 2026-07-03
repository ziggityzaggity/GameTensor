import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/router/route_paths.dart';
import '../../../data/repositories/auth_repository.dart';

/// The absolute URL Supabase should redirect the recovery email back to.
/// Built from the running web origin so it works locally and once deployed,
/// and uses the hash-router form (`/#/reset-callback`) go_router serves on web.
/// This exact URL must be in the Supabase redirect allowlist.
String passwordResetRedirectUrl() {
  final base = Uri.base;
  return '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}/#${RoutePaths.resetPassword}';
}

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Failure?> signUp(String email, String password) => _run(
        () => ref.read(authRepositoryProvider).signUpWithEmail(email: email, password: password),
      );

  Future<Failure?> signIn(String email, String password) => _run(
        () => ref.read(authRepositoryProvider).signInWithEmail(email: email, password: password),
      );

  Future<Failure?> signInWithGoogle() =>
      _run(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<Failure?> signInWithApple() =>
      _run(() => ref.read(authRepositoryProvider).signInWithApple());

  Future<Failure?> sendPasswordReset(String email) => _run(
        () => ref.read(authRepositoryProvider).sendPasswordReset(
              email,
              redirectTo: passwordResetRedirectUrl(),
            ),
      );

  Future<Failure?> updatePassword(String newPassword) =>
      _run(() => ref.read(authRepositoryProvider).updatePassword(newPassword));

  Future<Failure?> signOut() => _run(() => ref.read(authRepositoryProvider).signOut());

  Future<Failure?> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return null;
    } on Failure catch (f) {
      state = AsyncError(f, StackTrace.current);
      return f;
    } catch (e) {
      final f = UnknownFailure(e.toString());
      state = AsyncError(f, StackTrace.current);
      return f;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);
