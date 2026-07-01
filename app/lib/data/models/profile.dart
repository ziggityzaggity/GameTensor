import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

enum ProfileVisibility {
  @JsonValue('private')
  private,
  @JsonValue('friends')
  friends,
  @JsonValue('public')
  public,
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    @Default(ProfileVisibility.public) ProfileVisibility profileVisibility,
    String? onboardingCompletedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
