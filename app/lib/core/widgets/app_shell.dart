import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profiles_repository.dart';
import '../router/route_paths.dart';

/// Shared bottom-nav shell for the four main-app tabs. Wrap each top-level
/// screen body in this so navigation stays consistent across Search/Library/Lists/Profile.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.currentIndex, required this.body, this.title});

  final int currentIndex;
  final Widget body;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'GameTensor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(RoutePaths.search);
            case 1:
              context.go(RoutePaths.library);
            case 2:
              context.go(RoutePaths.lists);
            case 3:
              final username = profileAsync.valueOrNull?.username;
              if (username != null) context.go(RoutePaths.profilePath(username));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.videogame_asset), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Lists'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
