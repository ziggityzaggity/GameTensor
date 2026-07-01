import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_shell.dart';
import '../../application/profile_view_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByUsernameProvider(username));

    return AppShell(
      currentIndex: 3,
      title: '@$username',
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 12),
                Text(profile.displayName ?? profile.username,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('@${profile.username}', style: Theme.of(context).textTheme.bodyMedium),
                if (profile.bio != null) ...[
                  const SizedBox(height: 12),
                  Text(profile.bio!),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      ),
    );
  }
}
