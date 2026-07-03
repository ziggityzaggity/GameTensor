import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../../core/errors/failure.dart';
import '../models/profile.dart';
import 'auth_repository.dart';

class ProfilesRepository {
  ProfilesRepository(this._client);

  final SupabaseClient _client;

  // Postgres error codes surfaced when a profile write violates a constraint.
  static const _uniqueViolation = '23505';
  static const _checkViolation = '23514';

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

  /// Case-insensitive username prefix search for finding people to friend.
  /// The profiles RLS (`can_view_profile`) already filters out profiles the
  /// caller can't see, so private strangers never appear in results.
  Future<List<Profile>> searchByUsername(String prefix, {int limit = 20}) async {
    final trimmed = prefix.trim();
    if (trimmed.isEmpty) return const [];
    // Escape ILIKE wildcards in user input so `%`/`_` are matched literally.
    final escaped = trimmed.replaceAll('%', r'\%').replaceAll('_', r'\_');
    final rows = await _client
        .from('profiles')
        .select()
        .ilike('username', '$escaped%')
        .order('username')
        .limit(limit);
    return rows.map((r) => Profile.fromJson(r)).toList();
  }

  /// Updates the given fields on the user's own profile row. Only non-null
  /// arguments are written, so callers can update any subset.
  ///
  /// Throws [ValidationFailure] on a duplicate username (unique violation) or a
  /// bad username format that slipped past client validation (check violation),
  /// so the edit screen can show a friendly message instead of a raw 400.
  Future<void> updateProfile(
    String userId, {
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    ProfileVisibility? visibility,
  }) async {
    final updates = <String, dynamic>{
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (visibility != null) 'profile_visibility': visibility.name,
    };
    if (updates.isEmpty) return;
    try {
      await _client.from('profiles').update(updates).eq('id', userId);
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolation) {
        throw const ValidationFailure('That username is already taken');
      }
      if (e.code == _checkViolation) {
        throw const ValidationFailure('That username is not allowed');
      }
      rethrow;
    }
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
