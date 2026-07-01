import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../application/lists_controller.dart';

class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(listDetailProvider(listId));

    return Scaffold(
      appBar: AppBar(title: const Text('List')),
      body: entriesAsync.when(
        data: (entries) => ReorderableListView.builder(
          itemCount: entries.length,
          // onReorderItem already adjusts newIndex for the removed item, so no
          // manual oldIndex/newIndex correction is needed.
          onReorderItem: (oldIndex, newIndex) {
            ref
                .read(listsActionsProvider)
                .reorder(listId, entries[oldIndex].item.id, newIndex);
          },
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              key: ValueKey(entry.item.id),
              title: Text(entry.game?.canonicalName ?? 'Unknown game'),
              subtitle: entry.item.note != null ? Text(entry.item.note!) : null,
              onTap: () => context.push(RoutePaths.gameDetailPath(entry.item.gameId)),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load list: $e')),
      ),
    );
  }
}
