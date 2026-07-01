// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomListImpl _$$CustomListImplFromJson(Map<String, dynamic> json) =>
    _$CustomListImpl(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      visibility:
          $enumDecodeNullable(_$ListVisibilityEnumMap, json['visibility']) ??
              ListVisibility.private,
      coverImageUrl: json['cover_image_url'] as String?,
    );

Map<String, dynamic> _$$CustomListImplToJson(_$CustomListImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'owner_id': instance.ownerId,
      'title': instance.title,
      'description': instance.description,
      'visibility': _$ListVisibilityEnumMap[instance.visibility]!,
      'cover_image_url': instance.coverImageUrl,
    };

const _$ListVisibilityEnumMap = {
  ListVisibility.private: 'private',
  ListVisibility.friends: 'friends',
  ListVisibility.public: 'public',
};

_$ListItemImpl _$$ListItemImplFromJson(Map<String, dynamic> json) =>
    _$ListItemImpl(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      gameId: json['game_id'] as String,
      position: (json['position'] as num).toInt(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$ListItemImplToJson(_$ListItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'list_id': instance.listId,
      'game_id': instance.gameId,
      'position': instance.position,
      'note': instance.note,
    };
