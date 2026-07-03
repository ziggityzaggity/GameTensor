import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';

/// True while a password-recovery flow is active — i.e. Supabase has emitted
/// `AuthChangeEvent.passwordRecovery` (opening the recovery deep link) and the
/// user has not yet finished (a subsequent `userUpdated`/`signedOut` clears it).
///
/// The router reads this to let the recovery session reach `/reset-callback`
/// instead of being swept through the normal auth/onboarding gate: a recovery
/// session is otherwise indistinguishable from a signed-in one.
final passwordRecoveryProvider = NotifierProvider<PasswordRecoveryNotifier, bool>(
  PasswordRecoveryNotifier.new,
);

class PasswordRecoveryNotifier extends Notifier<bool> {
  @override
  bool build() {
    final sub = ref.read(authRepositoryProvider).authStateChanges.listen((data) {
      switch (data.event) {
        case AuthChangeEvent.passwordRecovery:
          state = true;
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.signedOut:
          state = false;
        default:
          break;
      }
    });
    ref.onDispose(sub.cancel);
    return false;
  }
}
