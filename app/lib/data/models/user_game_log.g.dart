// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_game_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserGameLogImpl _$$UserGameLogImplFromJson(Map<String, dynamic> json) =>
    _$UserGameLogImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gameId: json['game_id'] as String,
      completionStatusId: (json['completion_status_id'] as num).toInt(),
      liked: json['liked'] as bool?,
      hoursPlayed: (json['hours_played'] as num?)?.toDouble(),
      hoursSource: json['hours_source'] as String? ?? 'manual',
      lastPlayedAt: json['last_played_at'] as String?,
      startedAt: json['started_at'] as String?,
      finishedAt: json['finished_at'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserGameLogImplToJson(_$UserGameLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'game_id': instance.gameId,
      'completion_status_id': instance.completionStatusId,
      'liked': instance.liked,
      'hours_played': instance.hoursPlayed,
      'hours_source': instance.hoursSource,
      'last_played_at': instance.lastPlayedAt,
      'started_at': instance.startedAt,
      'finished_at': instance.finishedAt,
      'is_favorite': instance.isFavorite,
    };
