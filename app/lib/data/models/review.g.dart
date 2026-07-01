// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReviewImpl _$$ReviewImplFromJson(Map<String, dynamic> json) => _$ReviewImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gameId: json['game_id'] as String,
      body: json['body'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      containsSpoilers: json['contains_spoilers'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$$ReviewImplToJson(_$ReviewImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'game_id': instance.gameId,
      'body': instance.body,
      'rating': instance.rating,
      'contains_spoilers': instance.containsSpoilers,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
