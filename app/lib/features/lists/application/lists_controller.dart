import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/custom_list.dart';
import '../../../data/models/game.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../data/repositories/lists_repository.dart';

final myListsProvider = FutureProvider<List<CustomList>>((ref) async {
  final userId = ref.read(authRepositoryProvider).currentUser?.id;
  if (userId == null) return [];
  return ref.read(listsRepositoryProvider).getListsForOwner(userId);
});

class ListDetailEntry {
  const ListDetailEntry({required this.item, required this.game});
  final ListItem item;
  final Game? game;
}

final listDetailProvider = FutureProvider.family<List<ListDetailEntry>, String>((ref, listId) async {
  final items = await ref.read(listsRepositoryProvider).getListItems(listId);
  final gamesRepo = ref.read(gamesRepositoryProvider);
  return Future.wait(
    items.map((item) async => ListDetailEntry(item: item, game: await gamesRepo.getGameDetail(item.gameId))),
  );
});

class ListsActions {
  ListsActions(this.ref);
  final Ref ref;

  Future<void> createList(String title, {ListVisibility visibility = ListVisibility.private}) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(listsRepositoryProvider).createList(userId, title, visibility: visibility);
    ref.invalidate(myListsProvider);
  }

  Future<void> addGame(String listId, String gameId) async {
    await ref.read(listsRepositoryProvider).addGameToList(listId, gameId);
    ref.invalidate(listDetailProvider(listId));
  }

  Future<void> reorder(String listId, String itemId, int newPosition) async {
    await ref.read(listsRepositoryProvider).reorderListItem(itemId, newPosition);
    ref.invalidate(listDetailProvider(listId));
  }
}

final listsActionsProvider = Provider<ListsActions>((ref) => ListsActions(ref));
