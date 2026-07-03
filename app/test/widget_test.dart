// Smoke tests that don't require the full app bootstrap (Supabase.initialize).
// The main app is auth-gated and network-backed, so we exercise pure units here:
// model JSON parsing and a leaf widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gametensor_app/core/widgets/completion_badge.dart';
import 'package:gametensor_app/data/models/completion_status.dart';
import 'package:gametensor_app/data/models/game.dart';
import 'package:gametensor_app/data/repositories/games_repository.dart';

void main() {
  group('playerRangeOverlaps', () {
    // Seed tabletop ranges: Catan 3-4, Wingspan 1-5, Codenames 2-8.
    test('min=5 matches games that seat at least 5 players', () {
      // "supports at least 5" => reqMin: 5, open-ended max.
      expect(playerRangeOverlaps(3, 4, reqMin: 5), isFalse); // Catan
      expect(playerRangeOverlaps(1, 5, reqMin: 5), isTrue); // Wingspan
      expect(playerRangeOverlaps(2, 8, reqMin: 5), isTrue); // Codenames
    });

    test('max bound excludes games whose minimum exceeds it', () {
      expect(playerRangeOverlaps(3, 4, reqMax: 2), isFalse); // Catan needs 3+
      expect(playerRangeOverlaps(1, 5, reqMax: 2), isTrue); // Wingspan plays 2
    });

    test('a bounded request keeps games whose range overlaps it', () {
      // Party night for exactly 6: only Codenames (2-8) fits.
      expect(playerRangeOverlaps(3, 4, reqMin: 6, reqMax: 6), isFalse);
      expect(playerRangeOverlaps(1, 5, reqMin: 6, reqMax: 6), isFalse);
      expect(playerRangeOverlaps(2, 8, reqMin: 6, reqMax: 6), isTrue);
    });

    test('no requested bounds matches any game with player data', () {
      expect(playerRangeOverlaps(3, 4), isTrue);
    });

    test('a game with no player data never matches a player filter', () {
      expect(playerRangeOverlaps(null, null, reqMin: 2), isFalse);
    });
  });

  test('Game.fromJson parses a video game row', () {
    final game = Game.fromJson({
      'id': '00000000-0000-0000-0000-000000000002',
      'kind': 'video_game',
      'canonical_name': 'Elden Ring',
      'slug': 'elden-ring',
      'igdb_id': 119133,
    });

    expect(game.canonicalName, 'Elden Ring');
    expect(game.kind, GameKind.videoGame);
    expect(game.igdbId, 119133);
  });

  testWidgets('CompletionBadge renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompletionBadge(
            status: CompletionStatus(id: 6, code: 'completed_100', label: '100% Complete'),
          ),
        ),
      ),
    );

    expect(find.text('100% Complete'), findsOneWidget);
  });
}
