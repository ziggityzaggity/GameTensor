import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/game.dart';
import '../../../data/repositories/games_repository.dart';

class SearchFilters {
  const SearchFilters({this.kind});
  final GameKind? kind;

  SearchFilters copyWith({GameKind? kind}) => SearchFilters(kind: kind ?? this.kind);
}

class SearchState {
  const SearchState({this.query = '', this.filters = const SearchFilters(), this.results = const [], this.isLoading = false});

  final String query;
  final SearchFilters filters;
  final List<Game> results;
  final bool isLoading;

  SearchState copyWith({String? query, SearchFilters? filters, List<Game>? results, bool? isLoading}) {
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

    var results = await repo.searchLocal(query, kind: state.filters.kind);

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
      results = await repo.searchLocal(query, kind: state.filters.kind);
    }

    state = state.copyWith(results: results, isLoading: false);
  }

  void setKindFilter(GameKind? kind) {
    state = state.copyWith(filters: state.filters.copyWith(kind: kind));
    search(state.query);
  }
}

final searchControllerProvider = NotifierProvider<SearchController, SearchState>(SearchController.new);
