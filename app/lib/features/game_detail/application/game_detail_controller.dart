import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/game.dart';
import '../../../data/models/review.dart';
import '../../../data/models/user_game_log.dart';
import '../../../data/repositories/game_logs_repository.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../data/repositories/reviews_repository.dart';
import '../../../data/repositories/auth_repository.dart';

final gameDetailProvider = FutureProvider.family<Game?, String>((ref, gameId) {
  return ref.read(gamesRepositoryProvider).getGameDetail(gameId);
});

final gameReviewsProvider = FutureProvider.family<List<Review>, String>((ref, gameId) {
  return ref.read(reviewsRepositoryProvider).getReviewsForGame(gameId);
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
  }

  Future<void> submitReview(String gameId, String body, {double? rating}) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(reviewsRepositoryProvider).upsertReview(userId, gameId, body: body, rating: rating);
    ref.invalidate(gameReviewsProvider(gameId));
  }
}

final gameDetailActionsProvider = Provider<GameDetailActions>((ref) => GameDetailActions(ref));
