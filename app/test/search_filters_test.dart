// Pure-logic tests for the search filter value object and snake_case model
// parsing — the two client-side pieces of search behavior that are testable
// without a backend. The DB-side query behavior is covered by the pgTAP suite
// (supabase/tests/search_queries.sql).

import 'package:flutter_test/flutter_test.dart';

import 'package:gametensor_app/data/models/game.dart';
import 'package:gametensor_app/data/repositories/games_repository.dart';

void main() {
  group('GameSearchFilters.copyWith', () {
    const base = GameSearchFilters(
      kind: GameKind.tabletopGame,
      genreId: 4,
      platformId: 9,
      minPlayers: 2,
      maxPlayers: 6,
    );

    test('no arguments preserves every field', () {
      final copy = base.copyWith();
      expect(copy.kind, GameKind.tabletopGame);
      expect(copy.genreId, 4);
      expect(copy.platformId, 9);
      expect(copy.minPlayers, 2);
      expect(copy.maxPlayers, 6);
    });

    test('updates only the targeted field, leaving the rest intact', () {
      final copy = base.copyWith(genreId: 7);
      expect(copy.genreId, 7);
      expect(copy.kind, GameKind.tabletopGame);
      expect(copy.platformId, 9);
    });

    test('can explicitly CLEAR a field to null (the sentinel\'s purpose)', () {
      // A plain nullable copyWith could not distinguish "omitted" from "set to
      // null"; the sentinel lets the UI clear a filter chip back to "Any".
      final cleared = base.copyWith(genreId: null, platformId: null);
      expect(cleared.genreId, isNull);
      expect(cleared.platformId, isNull);
      // untouched fields survive the clear
      expect(cleared.kind, GameKind.tabletopGame);
      expect(cleared.minPlayers, 2);
    });

    test('hasPlayerFilter reflects whether either player bound is set', () {
      expect(const GameSearchFilters().hasPlayerFilter, isFalse);
      expect(const GameSearchFilters(minPlayers: 3).hasPlayerFilter, isTrue);
      expect(const GameSearchFilters(maxPlayers: 5).hasPlayerFilter, isTrue);
      // clearing both bounds turns the player filter off again
      expect(base.copyWith(minPlayers: null, maxPlayers: null).hasPlayerFilter, isFalse);
    });
  });

  group('Game.fromJson snake_case parsing (build.yaml field_rename guard)', () {
    test('parses a tabletop game with nested tabletop_game_details', () {
      final game = Game.fromJson({
        'id': '00000000-0000-0000-0000-000000000102',
        'kind': 'tabletop_game',
        'canonical_name': 'Wingspan',
        'slug': 'wingspan',
        'bgg_id': 266192,
        'popularity_score': 8.1,
        'tabletop_game_details': {
          'game_id': '00000000-0000-0000-0000-000000000102',
          'min_players': 1,
          'max_players': 5,
          'min_playtime_minutes': 40,
          'max_playtime_minutes': 70,
          'bgg_rank': 20,
        },
      });

      expect(game.kind, GameKind.tabletopGame);
      expect(game.bggId, 266192);
      // The nested snake_case keys must map to the camelCase freezed fields —
      // this is exactly what regressed before build.yaml's field_rename: snake.
      expect(game.tabletopGameDetails?.minPlayers, 1);
      expect(game.tabletopGameDetails?.maxPlayers, 5);
      expect(game.tabletopGameDetails?.bggRank, 20);
    });
  });
}
