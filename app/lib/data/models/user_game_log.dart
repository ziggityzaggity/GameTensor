import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_game_log.freezed.dart';
part 'user_game_log.g.dart';

@freezed
class UserGameLog with _$UserGameLog {
  const factory UserGameLog({
    required String id,
    required String userId,
    required String gameId,
    required int completionStatusId,
    bool? liked,
    double? hoursPlayed,
    @Default('manual') String hoursSource,
    String? lastPlayedAt,
    String? startedAt,
    String? finishedAt,
    @Default(false) bool isFavorite,
  }) = _UserGameLog;

  factory UserGameLog.fromJson(Map<String, dynamic> json) =>
      _$UserGameLogFromJson(json);
}
