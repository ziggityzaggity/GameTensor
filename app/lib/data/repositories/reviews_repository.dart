import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/review.dart';

class ReviewsRepository {
  ReviewsRepository(this._client);

  final SupabaseClient _client;

  Future<List<Review>> getReviewsForGame(String gameId) async {
    final rows = await _client
        .from('reviews')
        .select()
        .eq('game_id', gameId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return rows.map((r) => Review.fromJson(r)).toList();
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
