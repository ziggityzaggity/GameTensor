import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../models/profile.dart';
import 'auth_repository.dart';

class ProfilesRepository {
  ProfilesRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> getProfile(String userId) async {
    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  Future<Profile?> getProfileByUsername(String username) async {
    final row = await _client.from('profiles').select().eq('username', username).maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  Future<void> updateProfile(
    String userId, {
    String? displayName,
    String? bio,
    String? avatarUrl,
    ProfileVisibility? visibility,
  }) async {
    final updates = <String, dynamic>{
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (visibility != null) 'profile_visibility': visibility.name,
    };
    if (updates.isEmpty) return;
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<void> completeOnboarding(String userId) async {
    await _client
        .from('profiles')
        .update({'onboarding_completed_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }
}

final profilesRepositoryProvider = Provider<ProfilesRepository>((ref) {
  return ProfilesRepository(supabase);
});

/// The signed-in user's own profile; the router's onboarding gate reads this
/// via `currentProfileProvider.future` to decide whether to redirect.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  final userId = authState?.session?.user.id ?? ref.read(authRepositoryProvider).currentUser?.id;
  if (userId == null) return null;
  return ref.read(profilesRepositoryProvider).getProfile(userId);
});
