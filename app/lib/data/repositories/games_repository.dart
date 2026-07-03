import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/game.dart';

/// The set of catalog filters a search can apply. Grouping them in one value
/// object keeps [GamesRepository.searchLocal]'s signature stable as filters grow
/// and lets the UI thread selections through a single object.
class GameSearchFilters {
  const GameSearchFilters({
    this.kind,
    this.genreId,
    this.platformId,
    this.minPlayers,
    this.maxPlayers,
  });

  final GameKind? kind;
  final int? genreId;
  final int? platformId;

  /// The requested player-count range. Either bound may be set independently;
  /// a game matches when its tabletop player range overlaps this one.
  final int? minPlayers;
  final int? maxPlayers;

  bool get hasPlayerFilter => minPlayers != null || maxPlayers != null;

  /// Returns a copy overriding only the passed fields. Each parameter defaults
  /// to a sentinel so callers can explicitly clear a filter by passing `null`
  /// (a plain nullable copyWith can't tell "omitted" from "set to null").
  GameSearchFilters copyWith({
    Object? kind = _unset,
    Object? genreId = _unset,
    Object? platformId = _unset,
    Object? minPlayers = _unset,
    Object? maxPlayers = _unset,
  }) {
    return GameSearchFilters(
      kind: kind == _unset ? this.kind : kind as GameKind?,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      platformId: platformId == _unset ? this.platformId : platformId as int?,
      minPlayers: minPlayers == _unset ? this.minPlayers : minPlayers as int?,
      maxPlayers: maxPlayers == _unset ? this.maxPlayers : maxPlayers as int?,
    );
  }
}

const _unset = Object();

/// True when a game supporting [gameMin]..[gameMax] players can accommodate a
/// group anywhere in the requested [reqMin]..[reqMax] range. Overlap (not
/// containment) is the right semantics: "min=5" means "can seat at least 5",
/// which a 2-8 game satisfies. Either requested bound may be null (open-ended).
/// Exposed as a pure function so the predicate is unit-testable without a DB;
/// the repository applies the equivalent as PostgREST filters.
bool playerRangeOverlaps(
  int? gameMin,
  int? gameMax, {
  int? reqMin,
  int? reqMax,
}) {
  // A game with no player data can't be shown to match a player-count filter.
  if (gameMin == null && gameMax == null) return false;
  if (reqMax != null && gameMin != null && gameMin > reqMax) return false;
  if (reqMin != null && gameMax != null && gameMax < reqMin) return false;
  return true;
}

/// Local-first search with remote-upsert-on-miss: the UI always reads from our
/// own Postgres `games` table; when local results are thin, `igdb-search`/
/// `bgg-search` Edge Functions are invoked to pull fresh data from IGDB/BGG,
/// upsert it, and the caller re-queries local search to pick it up.
class GamesRepository {
  GamesRepository(this._client);

  final SupabaseClient _client;

  static const _detailEmbeds =
      'video_game_details(*), tabletop_game_details(*), game_platforms(platform_id), game_genres(genre_id)';

  Future<List<Game>> searchLocal(
    String query, {
    GameSearchFilters filters = const GameSearchFilters(),
    int limit = 30,
  }) async {
    var builder = _client.from('games').select(_selectFor(filters));

    if (query.trim().isNotEmpty) {
      // websearch_to_tsquery never raises syntax errors, so raw user input
      // (operators, quotes, punctuation) is safe to pass straight through.
      builder = builder.textSearch(
        'search_tsv',
        query,
        config: 'simple',
        type: TextSearchType.websearch,
      );
    }
    if (filters.kind != null) {
      builder = builder.eq(
        'kind',
        filters.kind == GameKind.videoGame ? 'video_game' : 'tabletop_game',
      );
    }
    if (filters.genreId != null) {
      builder = builder.eq('game_genres.genre_id', filters.genreId!);
    }
    if (filters.platformId != null) {
      builder = builder.eq('game_platforms.platform_id', filters.platformId!);
    }
    if (filters.minPlayers != null) {
      // Overlap: the game must seat at least the requested minimum.
      builder = builder.gte('tabletop_game_details.max_players', filters.minPlayers!);
    }
    if (filters.maxPlayers != null) {
      // Overlap: the game's minimum must fit within the requested maximum.
      builder = builder.lte('tabletop_game_details.min_players', filters.maxPlayers!);
    }

    final rows = await builder.order('popularity_score', ascending: false).limit(limit);
    return rows.map((r) => Game.fromJson(r)).toList();
  }

  /// Builds the `select` string, promoting a related resource to an `!inner`
  /// join only when it is being filtered — an embedded filter restricts parent
  /// rows only across an inner join, and non-filtered embeds stay outer so
  /// games without that relation still return.
  String _selectFor(GameSearchFilters filters) {
    final genres = filters.genreId != null
        ? 'game_genres!inner(genre_id)'
        : 'game_genres(genre_id)';
    final platforms = filters.platformId != null
        ? 'game_platforms!inner(platform_id)'
        : 'game_platforms(platform_id)';
    final tabletop = filters.hasPlayerFilter
        ? 'tabletop_game_details!inner(*)'
        : 'tabletop_game_details(*)';
    return '*, video_game_details(*), $tabletop, $platforms, $genres';
  }

  /// Invokes the IGDB/BGG Edge Functions when local search is thin; results are
  /// upserted server-side, so a follow-up `searchLocal` call will find them.
  Future<void> searchRemoteFallback(String query, {required GameKind kind}) async {
    final functionName = kind == GameKind.videoGame ? 'igdb-search' : 'bgg-search';
    await _client.functions.invoke(functionName, body: {'query': query});
  }

  Future<Game?> getGameDetail(String id) async {
    final row = await _client
        .from('games')
        .select('*, $_detailEmbeds')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return Game.fromJson(row);
  }

  /// Batched lookup for a set of ids, used to render inline game cards (e.g. the
  /// AI assistant's retrieved recommendations) without N round trips. Results
  /// are reordered to match [ids] since PostgREST does not preserve `in()` order.
  Future<List<Game>> getGamesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _client.from('games').select('*, $_detailEmbeds').inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: Game.fromJson(r)};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }
}

final gamesRepositoryProvider = Provider<GamesRepository>((ref) {
  return GamesRepository(supabase);
});
