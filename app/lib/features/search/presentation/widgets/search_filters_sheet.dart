import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/game.dart';
import '../../application/search_controller.dart';

class SearchFiltersSheet extends ConsumerWidget {
  const SearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentKind = ref.watch(searchControllerProvider).filters.kind;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by kind', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: currentKind == null,
                onSelected: (_) => ref.read(searchControllerProvider.notifier).setKindFilter(null),
              ),
              ChoiceChip(
                label: const Text('Video games'),
                selected: currentKind == GameKind.videoGame,
                onSelected: (_) =>
                    ref.read(searchControllerProvider.notifier).setKindFilter(GameKind.videoGame),
              ),
              ChoiceChip(
                label: const Text('Tabletop games'),
                selected: currentKind == GameKind.tabletopGame,
                onSelected: (_) =>
                    ref.read(searchControllerProvider.notifier).setKindFilter(GameKind.tabletopGame),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
