// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lookup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GenreImpl _$$GenreImplFromJson(Map<String, dynamic> json) => _$GenreImpl(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      displayName: json['display_name'] as String,
    );

Map<String, dynamic> _$$GenreImplToJson(_$GenreImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'display_name': instance.displayName,
    };

_$PlatformImpl _$$PlatformImplFromJson(Map<String, dynamic> json) =>
    _$PlatformImpl(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      displayName: json['display_name'] as String,
    );

Map<String, dynamic> _$$PlatformImplToJson(_$PlatformImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'display_name': instance.displayName,
    };
