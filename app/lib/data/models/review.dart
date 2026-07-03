import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';
part 'review.g.dart';

@freezed
class Review with _$Review {
  const factory Review({
    required String id,
    required String userId,
    required String gameId,
    required String body,
    double? rating,
    @Default(false) bool containsSpoilers,
    required String createdAt,
    required String updatedAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}

/// A review joined with its author's public profile fields, for display on the
/// game-detail screen. Built from a PostgREST embed of `profiles`; the author
/// row may be absent if the profile isn't visible to the caller (RLS), so the
/// name fields are nullable.
class ReviewWithAuthor {
  const ReviewWithAuthor({required this.review, this.authorUsername, this.authorDisplayName});

  final Review review;
  final String? authorUsername;
  final String? authorDisplayName;

  /// Best label for the author: display name, else username, else a fallback.
  String get authorLabel => authorDisplayName ?? authorUsername ?? 'Unknown';

  factory ReviewWithAuthor.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ReviewWithAuthor(
      review: Review.fromJson(json),
      authorUsername: profile?['username'] as String?,
      authorDisplayName: profile?['display_name'] as String?,
    );
  }
}
