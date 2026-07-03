import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/review.dart';

class ReviewsRepository {
  ReviewsRepository(this._client);

  final SupabaseClient _client;

  /// Reviews for a game, each joined with its author's public profile fields
  /// (username/display name) via a PostgREST embed. RLS already filters out
  /// reviews whose author isn't visible to the caller.
  Future<List<ReviewWithAuthor>> getReviewsForGame(String gameId) async {
    // Disambiguate the embed with the FK name: reviews relates to profiles both
    // directly (user_id) and indirectly (via review_likes), so a bare
    // `profiles(...)` embed is ambiguous (PostgREST PGRST201).
    final rows = await _client
        .from('reviews')
        .select('*, profiles!reviews_user_id_fkey(username, display_name)')
        .eq('game_id', gameId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return rows.map((r) => ReviewWithAuthor.fromJson(r)).toList();
  }

  Future<void> upsertReview(
    String userId,
    String gameId, {
    required String body,
    double? rating,
    bool containsSpoilers = false,
  }) async {
    await _client.from('reviews').upsert({
      'user_id': userId,
      'game_id': gameId,
      'body': body,
      'rating': rating,
      'contains_spoilers': containsSpoilers,
    }, onConflict: 'user_id,game_id');
  }

  Future<void> deleteReview(String userId, String gameId) async {
    await _client
        .from('reviews')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .eq('game_id', gameId);
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(supabase);
});
