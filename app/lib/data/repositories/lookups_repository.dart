import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/completion_status.dart';
import '../models/lookup.dart';

/// Reads the small, static reference tables (`genres`, `platforms`,
/// `completion_status`) that drive filter controls and completion labels.
/// These are seeded once and effectively immutable, so callers cache the
/// results for the session via [FutureProvider]s.
class LookupsRepository {
  LookupsRepository(this._client);

  final SupabaseClient _client;

  Future<List<Genre>> getGenres() async {
    final rows = await _client.from('genres').select().order('display_name');
    return rows.map((r) => Genre.fromJson(r)).toList();
  }

  Future<List<Platform>> getPlatforms() async {
    final rows = await _client.from('platforms').select().order('display_name');
    return rows.map((r) => Platform.fromJson(r)).toList();
  }

  Future<List<CompletionStatus>> getCompletionStatuses() async {
    final rows = await _client.from('completion_status').select().order('id');
    return rows.map((r) => CompletionStatus.fromJson(r)).toList();
  }
}

final lookupsRepositoryProvider = Provider<LookupsRepository>((ref) {
  return LookupsRepository(supabase);
});

/// Session-cached lookup lists, each loaded once from the DB and reused across
/// every feature (search filters, completion badges, onboarding, etc.).
final genresProvider = FutureProvider<List<Genre>>((ref) {
  return ref.read(lookupsRepositoryProvider).getGenres();
});

final platformsProvider = FutureProvider<List<Platform>>((ref) {
  return ref.read(lookupsRepositoryProvider).getPlatforms();
});

final completionStatusesProvider = FutureProvider<List<CompletionStatus>>((ref) {
  return ref.read(lookupsRepositoryProvider).getCompletionStatuses();
});

/// Derived `id -> label` map for the completion scale, so screens can render a
/// stored `completion_status_id` without re-fetching or hardcoding labels.
final completionStatusLabelsProvider = FutureProvider<Map<int, String>>((ref) async {
  final statuses = await ref.watch(completionStatusesProvider.future);
  return {for (final s in statuses) s.id: s.label};
});
