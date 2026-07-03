import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';
import '../../../data/models/game.dart';
import '../../../data/repositories/games_repository.dart';

/// What the user did with a recommendation shown on the rail. Dismissals feed
/// the engine's decay (0.5^d per dismissal); clicks are recorded for analytics.
enum ImpressionAction { clicked, dismissed }

/// One "For You" rail entry: the hydrated game plus the engine's score and the
/// strategy that produced it ('cf' | 'cold_start'), which is echoed back when
/// logging impressions so feedback is attributable to a strategy.
class RecommendedGame {
  const RecommendedGame({
    required this.game,
    required this.score,
    required this.strategy,
  });

  final Game game;
  final double score;
  final String strategy;
}

class RecommendationsRepository {
  RecommendationsRepository(this._client, this._gamesRepository);

  final SupabaseClient _client;
  final GamesRepository _gamesRepository;

  /// The user's precomputed rail, best first, hydrated to full [Game] rows in
  /// one batched lookup. RLS (owner-only SELECT) already scopes rows to the
  /// caller; the explicit user filter just states intent.
  Future<List<RecommendedGame>> getForYou(String userId, {int limit = 20}) async {
    final rows = await _client
        .from('user_recommendations')
        .select('game_id, score, strategy')
        .eq('user_id', userId)
        .order('score', ascending: false)
        .limit(limit);
    if (rows.isEmpty) return const [];

    final ids = [for (final r in rows) r['game_id'] as String];
    final games = await _gamesRepository.getGamesByIds(ids);
    final byId = {for (final g in games) g.id: g};

    return [
      for (final r in rows)
        if (byId[r['game_id']] case final Game game)
          RecommendedGame(
            game: game,
            score: (r['score'] as num).toDouble(),
            strategy: r['strategy'] as String,
          ),
    ];
  }

  /// Records rail feedback. A DB trigger rescores this user's recommendations
  /// in the same transaction, so a 'dismissed' insert is reflected in the very
  /// next [getForYou] read.
  Future<void> logImpression(
    String userId,
    String gameId, {
    required String strategy,
    required ImpressionAction action,
  }) async {
    await _client.from('recommendation_impressions').insert({
      'user_id': userId,
      'game_id': gameId,
      'strategy': strategy,
      'action': action.name,
    });
  }
}

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>((ref) {
  return RecommendationsRepository(supabase, ref.read(gamesRepositoryProvider));
});
