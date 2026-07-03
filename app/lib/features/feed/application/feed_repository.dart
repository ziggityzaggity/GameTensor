import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';
import '../../../data/models/custom_list.dart';
import '../../../data/models/game.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/friends_repository.dart';
import 'activity_item.dart';

/// Builds a query-time UNION of friends' recent activity across three source
/// tables. There is no denormalized feed table (per the plan); each page is
/// assembled on demand and merged in memory via [mergeActivity].
class FeedRepository {
  FeedRepository(this._client, this._friends);

  final SupabaseClient _client;
  final FriendsRepository _friends;

  // Embeds pull the actor profile and the target game/list alongside each row.
  static const _game = 'games(*, video_game_details(*), tabletop_game_details(*))';
  static const _actorCols = 'id, username, display_name, avatar_url';
  // user_game_logs has a single FK to profiles, so the bare embed is fine.
  static const _actor = 'profiles($_actorCols)';
  // reviews relates to profiles twice (user_id and, indirectly, review_likes),
  // so its actor embed must name the FK or PostgREST errors (PGRST201).
  static const _reviewActor = 'profiles!reviews_user_id_fkey($_actorCols)';

  /// A page of merged, newest-first friends' activity. [before] is a
  /// timestamp cursor: only rows strictly older than it are returned, so the
  /// screen paginates by passing the oldest item's timestamp back in.
  ///
  /// The queries are scoped to friend ids (from [FriendsRepository.friends]) in
  /// addition to RLS. RLS alone would let a *public* profile's activity through
  /// even if they aren't a friend; scoping to friend ids keeps the feed
  /// friends-only by design, which is the intended product behaviour.
  Future<List<ActivityItem>> friendsActivity({
    int limit = 30,
    DateTime? before,
  }) async {
    final friends = await _friends.friends();
    final friendIds = friends.map((f) => f.otherUserId).toList();
    if (friendIds.isEmpty) return const [];

    final cursor = before?.toIso8601String();
    final results = await Future.wait([
      _gameLogs(friendIds, limit: limit, before: cursor),
      _reviews(friendIds, limit: limit, before: cursor),
      _lists(friendIds, limit: limit, before: cursor),
    ]);

    return mergeActivity(results, limit: limit);
  }

  Future<List<ActivityItem>> _gameLogs(
    List<String> friendIds, {
    required int limit,
    String? before,
  }) async {
    var q = _client
        .from('user_game_logs')
        .select('updated_at, liked, completion_status_id, $_actor, $_game')
        .inFilter('user_id', friendIds);
    if (before != null) q = q.lt('updated_at', before);
    final rows = await q.order('updated_at', ascending: false).limit(limit);

    return rows
        .map((r) {
          final actor = _parseActor(r);
          final game = _parseGame(r);
          if (actor == null || game == null) return null;
          return GameLoggedActivity(
            actor: actor,
            timestamp: DateTime.parse(r['updated_at'] as String),
            game: game,
            liked: r['liked'] as bool?,
            completionStatusId: r['completion_status_id'] as int,
          );
        })
        .whereType<ActivityItem>()
        .toList();
  }

  Future<List<ActivityItem>> _reviews(
    List<String> friendIds, {
    required int limit,
    String? before,
  }) async {
    var q = _client
        .from('reviews')
        .select('updated_at, rating, $_reviewActor, $_game')
        .inFilter('user_id', friendIds)
        .isFilter('deleted_at', null);
    if (before != null) q = q.lt('updated_at', before);
    final rows = await q.order('updated_at', ascending: false).limit(limit);

    return rows
        .map((r) {
          final actor = _parseActor(r);
          final game = _parseGame(r);
          if (actor == null || game == null) return null;
          return ReviewWroteActivity(
            actor: actor,
            timestamp: DateTime.parse(r['updated_at'] as String),
            game: game,
            rating: (r['rating'] as num?)?.toDouble(),
          );
        })
        .whereType<ActivityItem>()
        .toList();
  }

  Future<List<ActivityItem>> _lists(
    List<String> friendIds, {
    required int limit,
    String? before,
  }) async {
    // custom_lists embeds its owner via the owner_id FK. Only non-private lists
    // are eligible; RLS already hides private lists, but filter here too so the
    // intent is explicit and the query is index-friendly.
    var q = _client
        .from('custom_lists')
        .select('*, profiles!custom_lists_owner_id_fkey(id, username, display_name, avatar_url)')
        .inFilter('owner_id', friendIds)
        .isFilter('deleted_at', null)
        .neq('visibility', 'private');
    if (before != null) q = q.lt('updated_at', before);
    final rows = await q.order('updated_at', ascending: false).limit(limit);

    return rows
        .map((r) {
          final profile = r['profiles'] as Map<String, dynamic>?;
          if (profile == null) return null;
          return ListCreatedActivity(
            actor: Profile.fromJson(profile),
            timestamp: DateTime.parse(r['updated_at'] as String),
            list: CustomList.fromJson(r),
          );
        })
        .whereType<ActivityItem>()
        .toList();
  }

  Profile? _parseActor(Map<String, dynamic> row) {
    final profile = row['profiles'] as Map<String, dynamic>?;
    return profile == null ? null : Profile.fromJson(profile);
  }

  Game? _parseGame(Map<String, dynamic> row) {
    final game = row['games'] as Map<String, dynamic>?;
    return game == null ? null : Game.fromJson(game);
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(supabase, ref.watch(friendsRepositoryProvider));
});

/// The first page of the friends activity feed. Watches [friendsProvider] so a
/// friend being added/removed rebuilds the feed (its contents are friend-scoped).
final feedProvider = FutureProvider<List<ActivityItem>>((ref) {
  ref.watch(friendsProvider);
  return ref.watch(feedRepositoryProvider).friendsActivity();
});
