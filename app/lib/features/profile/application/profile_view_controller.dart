import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile.dart';
import '../../../data/repositories/profiles_repository.dart';

final profileByUsernameProvider = FutureProvider.family<Profile?, String>((ref, username) {
  return ref.read(profilesRepositoryProvider).getProfileByUsername(username);
});
