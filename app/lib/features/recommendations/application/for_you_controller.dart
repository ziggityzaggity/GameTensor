import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../data/recommendations_repository.dart';

/// The signed-in user's "For You" rail, best-scored first. Re-watched on auth
/// changes so a sign-in/out swaps the rail; invalidated after any write that
/// the DB trigger rescores on (logs, reviews, dismissals) so the UI re-reads
/// the freshly recomputed rows.
final forYouRailProvider = FutureProvider<List<RecommendedGame>>((ref) async {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  final userId =
      authState?.session?.user.id ?? ref.read(authRepositoryProvider).currentUser?.id;
  if (userId == null) return const [];
  return ref.read(recommendationsRepositoryProvider).getForYou(userId);
});

/// Rail interactions, kept out of widgets so no Postgrest leaks into the
/// presentation layer.
class ForYouActions {
  ForYouActions(this.ref);

  final Ref ref;

  /// Fire-and-forget click logging: navigation must never wait on (or fail
  /// because of) analytics.
  Future<void> recordClick(RecommendedGame rec) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    try {
      await ref.read(recommendationsRepositoryProvider).logImpression(
            userId,
            rec.game.id,
            strategy: rec.strategy,
            action: ImpressionAction.clicked,
          );
    } catch (_) {
      // Best-effort; a lost click impression only costs analytics fidelity.
    }
  }

  /// Logs a dismissal, then re-reads the rail — the DB trigger has already
  /// decayed the dismissed game's score server-side by the time the insert
  /// returns, so the invalidated provider picks up the new ordering.
  Future<void> dismiss(RecommendedGame rec) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(recommendationsRepositoryProvider).logImpression(
          userId,
          rec.game.id,
          strategy: rec.strategy,
          action: ImpressionAction.dismissed,
        );
    ref.invalidate(forYouRailProvider);
  }
}

final forYouActionsProvider = Provider<ForYouActions>((ref) => ForYouActions(ref));
