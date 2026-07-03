import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../data/repositories/lookups_repository.dart';
import '../../application/library_controller.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final statusLabels = ref.watch(completionStatusLabelsProvider).valueOrNull ?? const {};

    return AppShell(
      currentIndex: 1,
      title: 'My Games',
      body: libraryAsync.when(
        data: (entries) => entries.isEmpty
            ? const Center(child: Text('No games logged yet. Search to add some!'))
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    leading: entry.game?.coverImageUrl != null
                        ? CircleAvatar(backgroundImage: NetworkImage(entry.game!.coverImageUrl!))
                        : const CircleAvatar(child: Icon(Icons.videogame_asset_outlined)),
                    title: Text(entry.game?.canonicalName ?? 'Unknown game'),
                    subtitle: Text(statusLabels[entry.log.completionStatusId] ?? 'Unknown'),
                    trailing: entry.log.liked == null
                        ? null
                        : Icon(entry.log.liked! ? Icons.thumb_up : Icons.thumb_down, size: 18),
                    onTap: () => context.push(RoutePaths.gameDetailPath(entry.log.gameId)),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load library: $e')),
      ),
    );
  }
}
