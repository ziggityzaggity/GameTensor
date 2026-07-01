import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/user_game_log.dart';

class GameLogsRepository {
  GameLogsRepository(this._client);

  final SupabaseClient _client;

  Future<UserGameLog?> getLogForGame(String userId, String gameId) async {
    final row = await _client
        .from('user_game_logs')
        .select()
        .eq('user_id', userId)
        .eq('game_id', gameId)
        .maybeSingle();
    if (row == null) return null;
    return UserGameLog.fromJson(row);
  }

  Future<List<UserGameLog>> getUserLibrary(String userId) async {
    final rows = await _client
        .from('user_game_logs')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return rows.map((r) => UserGameLog.fromJson(r)).toList();
  }

  Future<void> upsertLog(
    String userId,
    String gameId, {
    required int completionStatusId,
    bool? liked,
    double? hoursPlayed,
  }) async {
    await _client.from('user_game_logs').upsert({
      'user_id': userId,
      'game_id': gameId,
      'completion_status_id': completionStatusId,
      if (liked != null) 'liked': liked,
      if (hoursPlayed != null) 'hours_played': hoursPlayed,
    }, onConflict: 'user_id,game_id');
  }

  /// Used by the onboarding manual-add flow to record several games at once.
  Future<void> batchUpsertLogs(String userId, List<Map<String, dynamic>> entries) async {
    final rows = entries
        .map((e) => {
              'user_id': userId,
              'game_id': e['gameId'],
              'completion_status_id': e['completionStatusId'],
              if (e['liked'] != null) 'liked': e['liked'],
            })
        .toList();
    if (rows.isEmpty) return;
    await _client.from('user_game_logs').upsert(rows, onConflict: 'user_id,game_id');
  }
}

final gameLogsRepositoryProvider = Provider<GameLogsRepository>((ref) {
  return GameLogsRepository(supabase);
});
