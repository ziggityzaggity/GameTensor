import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/game.dart';
import '../../../data/models/review.dart';
import '../../../data/models/user_game_log.dart';
import '../../../data/repositories/game_logs_repository.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../data/repositories/reviews_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../recommendations/application/for_you_controller.dart';

final gameDetailProvider = FutureProvider.family<Game?, String>((ref, gameId) {
  return ref.read(gamesRepositoryProvider).getGameDetail(gameId);
});

final gameReviewsProvider = FutureProvider.family<List<ReviewWithAuthor>, String>((ref, gameId) {
  return ref.read(reviewsRepositoryProvider).getReviewsForGame(gameId);
});

/// The signed-in user's id, so the UI can gate edit/delete affordances to the
/// user's own review. Null when signed out.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.read(authRepositoryProvider).currentUser?.id;
});

final myGameLogProvider = FutureProvider.family<UserGameLog?, String>((ref, gameId) async {
  final userId = ref.read(authRepositoryProvider).currentUser?.id;
  if (userId == null) return null;
  return ref.read(gameLogsRepositoryProvider).getLogForGame(userId, gameId);
});

class GameDetailActions {
  GameDetailActions(this.ref);
  final Ref ref;

  Future<void> setCompletionStatus(String gameId, int completionStatusId, {bool? liked}) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(gameLogsRepositoryProvider).upsertLog(
          userId,
          gameId,
          completionStatusId: completionStatusId,
          liked: liked,
        );
    ref.invalidate(myGameLogProvider(gameId));
    // The DB trigger rescored this user's recommendations on the write above.
    ref.invalidate(forYouRailProvider);
  }

  Future<void> submitReview(
    String gameId,
    String body, {
    double? rating,
    bool containsSpoilers = false,
  }) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(reviewsRepositoryProvider).upsertReview(
          userId,
          gameId,
          body: body,
          rating: rating,
          containsSpoilers: containsSpoilers,
        );
    ref.invalidate(gameReviewsProvider(gameId));
    ref.invalidate(forYouRailProvider);
  }

  Future<void> deleteReview(String gameId) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(reviewsRepositoryProvider).deleteReview(userId, gameId);
    ref.invalidate(gameReviewsProvider(gameId));
    ref.invalidate(forYouRailProvider);
  }
}

final gameDetailActionsProvider = Provider<GameDetailActions>((ref) => GameDetailActions(ref));
