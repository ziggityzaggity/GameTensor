import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/custom_list.dart';

class ListsRepository {
  ListsRepository(this._client);

  final SupabaseClient _client;

  Future<List<CustomList>> getListsForOwner(String ownerId) async {
    final rows = await _client
        .from('custom_lists')
        .select()
        .eq('owner_id', ownerId)
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: false);
    return rows.map((r) => CustomList.fromJson(r)).toList();
  }

  Future<CustomList> createList(
    String ownerId,
    String title, {
    String? description,
    ListVisibility visibility = ListVisibility.private,
  }) async {
    final row = await _client
        .from('custom_lists')
        .insert({
          'owner_id': ownerId,
          'title': title,
          'description': description,
          'visibility': visibility.name,
        })
        .select()
        .single();
    return CustomList.fromJson(row);
  }

  Future<List<ListItem>> getListItems(String listId) async {
    final rows = await _client
        .from('list_items')
        .select()
        .eq('list_id', listId)
        .order('position');
    return rows.map((r) => ListItem.fromJson(r)).toList();
  }

  Future<void> addGameToList(String listId, String gameId, {int? position, String? note}) async {
    final resolvedPosition = position ?? await _nextPosition(listId);
    await _client.from('list_items').upsert({
      'list_id': listId,
      'game_id': gameId,
      'position': resolvedPosition,
      'note': note,
    }, onConflict: 'list_id,game_id');
  }

  Future<void> reorderListItem(String itemId, int newPosition) async {
    await _client.from('list_items').update({'position': newPosition}).eq('id', itemId);
  }

  Future<void> removeGameFromList(String listId, String gameId) async {
    await _client.from('list_items').delete().eq('list_id', listId).eq('game_id', gameId);
  }

  Future<int> _nextPosition(String listId) async {
    final rows = await _client
        .from('list_items')
        .select('position')
        .eq('list_id', listId)
        .order('position', ascending: false)
        .limit(1);
    if (rows.isEmpty) return 0;
    return (rows.first['position'] as int) + 1;
  }
}

final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  return ListsRepository(supabase);
});
