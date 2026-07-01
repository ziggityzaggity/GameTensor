import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/game.dart';
import '../../../data/models/user_game_log.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/game_logs_repository.dart';
import '../../../data/repositories/games_repository.dart';

class LibraryEntry {
  const LibraryEntry({required this.log, required this.game});
  final UserGameLog log;
  final Game? game;
}

final libraryProvider = FutureProvider<List<LibraryEntry>>((ref) async {
  final userId = ref.read(authRepositoryProvider).currentUser?.id;
  if (userId == null) return [];

  final logs = await ref.read(gameLogsRepositoryProvider).getUserLibrary(userId);
  final gamesRepo = ref.read(gamesRepositoryProvider);

  final entries = await Future.wait(
    logs.map((log) async => LibraryEntry(log: log, game: await gamesRepo.getGameDetail(log.gameId))),
  );
  return entries;
});
