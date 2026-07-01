// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileImpl _$$ProfileImplFromJson(Map<String, dynamic> json) =>
    _$ProfileImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      profileVisibility: $enumDecodeNullable(
              _$ProfileVisibilityEnumMap, json['profile_visibility']) ??
          ProfileVisibility.public,
      onboardingCompletedAt: json['onboarding_completed_at'] as String?,
    );

Map<String, dynamic> _$$ProfileImplToJson(_$ProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'profile_visibility':
          _$ProfileVisibilityEnumMap[instance.profileVisibility]!,
      'onboarding_completed_at': instance.onboardingCompletedAt,
    };

const _$ProfileVisibilityEnumMap = {
  ProfileVisibility.private: 'private',
  ProfileVisibility.friends: 'friends',
  ProfileVisibility.public: 'public',
};
