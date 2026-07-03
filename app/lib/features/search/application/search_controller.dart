import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/game.dart';
import '../../../data/repositories/games_repository.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.filters = const GameSearchFilters(),
    this.results = const [],
    this.isLoading = false,
  });

  final String query;
  final GameSearchFilters filters;
  final List<Game> results;
  final bool isLoading;

  SearchState copyWith({
    String? query,
    GameSearchFilters? filters,
    List<Game>? results,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchController extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true);
    final repo = ref.read(gamesRepositoryProvider);

    var results = await repo.searchLocal(query, filters: state.filters);

    // If local search is thin, fall back to live IGDB/BGG upsert-on-demand,
    // then re-query local search so the client always reads from our own schema.
    if (results.length < 3 && query.trim().isNotEmpty) {
      final kindsToTry = state.filters.kind != null
          ? [state.filters.kind!]
          : [GameKind.videoGame, GameKind.tabletopGame];
      for (final kind in kindsToTry) {
        try {
          await repo.searchRemoteFallback(query, kind: kind);
        } catch (_) {
          // Best-effort: ignore remote fallback failures, local results still show.
        }
      }
      results = await repo.searchLocal(query, filters: state.filters);
    }

    state = state.copyWith(results: results, isLoading: false);
  }

  void _applyFilters(GameSearchFilters filters) {
    state = state.copyWith(filters: filters);
    search(state.query);
  }

  void setKindFilter(GameKind? kind) {
    // Player-count only applies to tabletop; switching to video games clears it.
    if (kind == GameKind.videoGame) {
      _applyFilters(state.filters.copyWith(kind: kind, minPlayers: null, maxPlayers: null));
    } else {
      _applyFilters(state.filters.copyWith(kind: kind));
    }
  }

  void setGenreFilter(int? genreId) {
    _applyFilters(state.filters.copyWith(genreId: genreId));
  }

  void setPlatformFilter(int? platformId) {
    _applyFilters(state.filters.copyWith(platformId: platformId));
  }

  void setPlayerRange({int? minPlayers, int? maxPlayers}) {
    _applyFilters(state.filters.copyWith(minPlayers: minPlayers, maxPlayers: maxPlayers));
  }
}

final searchControllerProvider = NotifierProvider<SearchController, SearchState>(SearchController.new);
