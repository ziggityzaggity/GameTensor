import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/game.dart';

/// Local-first search with remote-upsert-on-miss: the UI always reads from our
/// own Postgres `games` table; when local results are thin, `igdb-search`/
/// `bgg-search` Edge Functions are invoked to pull fresh data from IGDB/BGG,
/// upsert it, and the caller re-queries local search to pick it up.
class GamesRepository {
  GamesRepository(this._client);

  final SupabaseClient _client;

  static const _selectWithDetails =
      '*, video_game_details(*), tabletop_game_details(*), game_platforms(platform_id), game_genres(genre_id)';

  Future<List<Game>> searchLocal(
    String query, {
    GameKind? kind,
    int? platformId,
    int? genreId,
    int limit = 30,
  }) async {
    var builder = _client.from('games').select(_selectWithDetails);

    if (query.trim().isNotEmpty) {
      builder = builder.textSearch('search_tsv', query, config: 'simple');
    }
    if (kind != null) {
      builder = builder.eq('kind', kind == GameKind.videoGame ? 'video_game' : 'tabletop_game');
    }

    final rows = await builder.order('popularity_score', ascending: false).limit(limit);
    return rows.map((r) => Game.fromJson(r)).toList();
  }

  /// Invokes the IGDB/BGG Edge Functions when local search is thin; results are
  /// upserted server-side, so a follow-up `searchLocal` call will find them.
  Future<void> searchRemoteFallback(String query, {required GameKind kind}) async {
    final functionName = kind == GameKind.videoGame ? 'igdb-search' : 'bgg-search';
    await _client.functions.invoke(functionName, body: {'query': query});
  }

  Future<Game?> getGameDetail(String id) async {
    final row = await _client.from('games').select(_selectWithDetails).eq('id', id).maybeSingle();
    if (row == null) return null;
    return Game.fromJson(row);
  }
}

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(supabase);
});
