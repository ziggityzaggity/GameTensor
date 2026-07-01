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
