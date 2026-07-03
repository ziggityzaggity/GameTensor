/// Client-side mirror of the DB constraint `profiles_username_format`
/// (`^[a-z0-9_]{3,30}$`, migration 0010) so we can reject bad input before it
/// round-trips and 400s. The DB remains the source of truth for uniqueness.
final _usernameFormat = RegExp(r'^[a-z0-9_]{3,30}$');

/// Returns a human-readable error for [value], or null if it is a valid
/// username. Kept pure (no Flutter/Supabase deps) so it can be unit-tested and
/// reused by both the profile-edit and onboarding username screens.
String? validateUsername(String value) {
  final username = value.trim();
  if (username.isEmpty) return 'Username is required';
  if (username.length < 3) return 'Must be at least 3 characters';
  if (username.length > 30) return 'Must be at most 30 characters';
  if (!_usernameFormat.hasMatch(username)) {
    return 'Only lowercase letters, numbers, and underscores';
  }
  return null;
}
