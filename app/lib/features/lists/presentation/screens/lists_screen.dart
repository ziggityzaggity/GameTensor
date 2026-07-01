import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../application/lists_controller.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(myListsProvider);

    return AppShell(
      currentIndex: 2,
      title: 'My Lists',
      body: Stack(
        children: [
          listsAsync.when(
            data: (lists) => lists.isEmpty
                ? const Center(child: Text('No lists yet. Tap + to create one.'))
                : ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return ListTile(
                        title: Text(list.title),
                        subtitle: Text(list.visibility.name),
                        onTap: () => context.push(RoutePaths.listDetailPath(list.id)),
                      );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load lists: $e')),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreateListDialog(context, ref),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateListDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New list'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      await ref.read(listsActionsProvider).createList(title);
    }
  }
}
