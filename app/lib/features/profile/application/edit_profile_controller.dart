import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/avatars_repository.dart';
import '../../../data/repositories/profiles_repository.dart';

/// A newly-picked avatar image waiting to be uploaded on save.
class PickedAvatar {
  const PickedAvatar({required this.bytes, required this.contentType});
  final Uint8List bytes;
  final String contentType;
}

/// Drives the edit-profile screen: uploads a newly-picked avatar (if any), then
/// persists the profile fields, and refreshes the cached profile providers.
class EditProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Saves the profile. Returns null on success, or a [Failure] the screen can
  /// surface (e.g. a duplicate username). Only the avatar is uploaded eagerly;
  /// everything else is a single profile update.
  Future<Failure?> save({
    required String username,
    required String displayName,
    required String bio,
    required ProfileVisibility visibility,
    PickedAvatar? newAvatar,
  }) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return const AuthFailure('Not signed in');

    state = const AsyncLoading();
    try {
      String? avatarUrl;
      if (newAvatar != null) {
        avatarUrl = await ref.read(avatarsRepositoryProvider).uploadAvatar(
              userId: userId,
              bytes: newAvatar.bytes,
              contentType: newAvatar.contentType,
            );
      }

      await ref.read(profilesRepositoryProvider).updateProfile(
            userId,
            username: username,
            displayName: displayName,
            bio: bio,
            avatarUrl: avatarUrl,
            visibility: visibility,
          );

      ref.invalidate(currentProfileProvider);
      state = const AsyncData(null);
      return null;
    } on Failure catch (f) {
      state = AsyncError(f, StackTrace.current);
      return f;
    } catch (e) {
      final f = UnknownFailure(e.toString());
      state = AsyncError(f, StackTrace.current);
      return f;
    }
  }
}

final editProfileControllerProvider =
    AsyncNotifierProvider<EditProfileController, void>(EditProfileController.new);
