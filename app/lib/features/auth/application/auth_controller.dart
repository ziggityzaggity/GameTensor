import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../data/repositories/auth_repository.dart';

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
