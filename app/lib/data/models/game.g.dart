// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameImpl _$$GameImplFromJson(Map<String, dynamic> json) => _$GameImpl(
      id: json['id'] as String,
      kind: $enumDecode(_$GameKindEnumMap, json['kind']),
      canonicalName: json['canonical_name'] as String,
      slug: json['slug'] as String,
      summary: json['summary'] as String?,
      releaseDate: json['release_date'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      igdbId: (json['igdb_id'] as num?)?.toInt(),
      bggId: (json['bgg_id'] as num?)?.toInt(),
      popularityScore: (json['popularity_score'] as num?)?.toDouble(),
      videoGameDetails: json['video_game_details'] == null
          ? null
          : VideoGameDetails.fromJson(
              json['video_game_details'] as Map<String, dynamic>),
      tabletopGameDetails: json['tabletop_game_details'] == null
          ? null
          : TabletopGameDetails.fromJson(
              json['tabletop_game_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GameImplToJson(_$GameImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$GameKindEnumMap[instance.kind]!,
      'canonical_name': instance.canonicalName,
      'slug': instance.slug,
      'summary': instance.summary,
      'release_date': instance.releaseDate,
      'cover_image_url': instance.coverImageUrl,
      'igdb_id': instance.igdbId,
      'bgg_id': instance.bggId,
      'popularity_score': instance.popularityScore,
      'video_game_details': instance.videoGameDetails,
      'tabletop_game_details': instance.tabletopGameDetails,
    };

const _$GameKindEnumMap = {
  GameKind.videoGame: 'video_game',
  GameKind.tabletopGame: 'tabletop_game',
};

_$VideoGameDetailsImpl _$$VideoGameDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$VideoGameDetailsImpl(
      gameId: json['game_id'] as String,
      igdbSlug: json['igdb_slug'] as String?,
      franchise: json['franchise'] as String?,
      gameModes: (json['game_modes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      esrbRating: json['esrb_rating'] as String?,
      metacriticScore: (json['metacritic_score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$VideoGameDetailsImplToJson(
        _$VideoGameDetailsImpl instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'igdb_slug': instance.igdbSlug,
      'franchise': instance.franchise,
      'game_modes': instance.gameModes,
      'esrb_rating': instance.esrbRating,
      'metacritic_score': instance.metacriticScore,
    };

_$TabletopGameDetailsImpl _$$TabletopGameDetailsImplFromJson(
        Map<String, dynamic> json) =>
    _$TabletopGameDetailsImpl(
      gameId: json['game_id'] as String,
      bggType: json['bgg_type'] as String?,
      minPlayers: (json['min_players'] as num?)?.toInt(),
      maxPlayers: (json['max_players'] as num?)?.toInt(),
      minPlaytimeMinutes: (json['min_playtime_minutes'] as num?)?.toInt(),
      maxPlaytimeMinutes: (json['max_playtime_minutes'] as num?)?.toInt(),
      minAge: (json['min_age'] as num?)?.toInt(),
      bggRank: (json['bgg_rank'] as num?)?.toInt(),
      bggAverageRating: (json['bgg_average_rating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$TabletopGameDetailsImplToJson(
        _$TabletopGameDetailsImpl instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'bgg_type': instance.bggType,
      'min_players': instance.minPlayers,
      'max_players': instance.maxPlayers,
      'min_playtime_minutes': instance.minPlaytimeMinutes,
      'max_playtime_minutes': instance.maxPlaytimeMinutes,
      'min_age': instance.minAge,
      'bgg_rank': instance.bggRank,
      'bgg_average_rating': instance.bggAverageRating,
    };
