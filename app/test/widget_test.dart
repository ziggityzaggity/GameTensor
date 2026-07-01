// Smoke tests that don't require the full app bootstrap (Supabase.initialize).
// The main app is auth-gated and network-backed, so we exercise pure units here:
// model JSON parsing and a leaf widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gametensor_app/core/widgets/completion_badge.dart';
import 'package:gametensor_app/data/models/completion_status.dart';
import 'package:gametensor_app/data/models/game.dart';

void main() {
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
