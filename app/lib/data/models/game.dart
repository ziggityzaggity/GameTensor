import 'package:freezed_annotation/freezed_annotation.dart';

part 'game.freezed.dart';
part 'game.g.dart';

enum GameKind {
  @JsonValue('video_game')
  videoGame,
  @JsonValue('tabletop_game')
  tabletopGame,
}

@freezed
class Game with _$Game {
  const factory Game({
    required String id,
    required GameKind kind,
    required String canonicalName,
    required String slug,
    String? summary,
    String? releaseDate,
    String? coverImageUrl,
    int? igdbId,
    int? bggId,
    double? popularityScore,
    VideoGameDetails? videoGameDetails,
    TabletopGameDetails? tabletopGameDetails,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}

@freezed
class VideoGameDetails with _$VideoGameDetails {
  const factory VideoGameDetails({
    required String gameId,
    String? igdbSlug,
    String? franchise,
    List<String>? gameModes,
    String? esrbRating,
    int? metacriticScore,
  }) = _VideoGameDetails;

  factory VideoGameDetails.fromJson(Map<String, dynamic> json) =>
      _$VideoGameDetailsFromJson(json);
}

@freezed
class TabletopGameDetails with _$TabletopGameDetails {
  const factory TabletopGameDetails({
    required String gameId,
    String? bggType,
    int? minPlayers,
    int? maxPlayers,
    int? minPlaytimeMinutes,
    int? maxPlaytimeMinutes,
    int? minAge,
    int? bggRank,
    double? bggAverageRating,
  }) = _TabletopGameDetails;

  factory TabletopGameDetails.fromJson(Map<String, dynamic> json) =>
      _$TabletopGameDetailsFromJson(json);
}
