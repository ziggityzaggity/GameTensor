// Unit tests for the pure feed merge/sort logic (no DB / no bootstrap needed).

import 'package:flutter_test/flutter_test.dart';
import 'package:gametensor_app/data/models/custom_list.dart';
import 'package:gametensor_app/data/models/game.dart';
import 'package:gametensor_app/data/models/profile.dart';
import 'package:gametensor_app/features/feed/application/activity_item.dart';

Profile _actor(String name) => Profile(id: name, username: name);

Game _game(String id) =>
    Game(id: id, kind: GameKind.videoGame, canonicalName: id, slug: id);

GameLoggedActivity _logged(String actor, DateTime t) => GameLoggedActivity(
      actor: _actor(actor),
      timestamp: t,
      game: _game('g'),
      completionStatusId: 6,
    );

ReviewWroteActivity _reviewed(String actor, DateTime t) => ReviewWroteActivity(
      actor: _actor(actor),
      timestamp: t,
      game: _game('g'),
    );

ListCreatedActivity _listed(String actor, DateTime t) => ListCreatedActivity(
      actor: _actor(actor),
      timestamp: t,
      list: CustomList(id: 'l', ownerId: actor, title: 'l'),
    );

void main() {
  group('mergeActivity', () {
    test('merges all sources newest-first', () {
      final result = mergeActivity([
        [_logged('a', DateTime.utc(2026, 7, 1))],
        [_reviewed('b', DateTime.utc(2026, 7, 3))],
        [_listed('c', DateTime.utc(2026, 7, 2))],
      ], limit: 30);

      expect(result.map((i) => i.actor.username).toList(), ['b', 'c', 'a']);
      // Each variant type is preserved through the merge.
      expect(result[0], isA<ReviewWroteActivity>());
      expect(result[1], isA<ListCreatedActivity>());
      expect(result[2], isA<GameLoggedActivity>());
    });

    test('caps the merged list at the limit', () {
      final result = mergeActivity([
        [
          _logged('a', DateTime.utc(2026, 7, 5)),
          _logged('a', DateTime.utc(2026, 7, 4)),
        ],
        [_reviewed('b', DateTime.utc(2026, 7, 3))],
      ], limit: 2);

      expect(result.length, 2);
      // Keeps the two newest across sources.
      expect(result.map((i) => i.timestamp).toList(),
          [DateTime.utc(2026, 7, 5), DateTime.utc(2026, 7, 4)]);
    });

    test('empty sources yield an empty feed', () {
      expect(mergeActivity([[], [], []], limit: 30), isEmpty);
    });
  });
}
