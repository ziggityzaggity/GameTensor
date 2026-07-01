// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completion_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CompletionStatusImpl _$$CompletionStatusImplFromJson(
        Map<String, dynamic> json) =>
    _$CompletionStatusImpl(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$$CompletionStatusImplToJson(
        _$CompletionStatusImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'label': instance.label,
    };
