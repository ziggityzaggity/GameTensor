import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/game.dart';
import '../../../../data/repositories/lookups_repository.dart';
import '../../application/search_controller.dart';

class SearchFiltersSheet extends ConsumerWidget {
  const SearchFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchControllerProvider).filters;
    final controller = ref.read(searchControllerProvider.notifier);
    final genres = ref.watch(genresProvider);
    final platforms = ref.watch(platformsProvider);
    // Player count is a tabletop-only attribute, so hide it for video games.
    final showPlayers = filters.kind != GameKind.videoGame;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kind', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: filters.kind == null,
                onSelected: (_) => controller.setKindFilter(null),
              ),
              ChoiceChip(
                label: const Text('Video games'),
                selected: filters.kind == GameKind.videoGame,
                onSelected: (_) => controller.setKindFilter(GameKind.videoGame),
              ),
              ChoiceChip(
                label: const Text('Tabletop games'),
                selected: filters.kind == GameKind.tabletopGame,
                onSelected: (_) => controller.setKindFilter(GameKind.tabletopGame),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Genre', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          genres.when(
            data: (items) => DropdownButton<int?>(
              isExpanded: true,
              value: filters.genreId,
              hint: const Text('Any genre'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any genre')),
                for (final g in items)
                  DropdownMenuItem(value: g.id, child: Text(g.displayName)),
              ],
              onChanged: controller.setGenreFilter,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load genres: $e'),
          ),
          const SizedBox(height: 16),
          Text('Platform', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          platforms.when(
            data: (items) => DropdownButton<int?>(
              isExpanded: true,
              value: filters.platformId,
              hint: const Text('Any platform'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any platform')),
                for (final p in items)
                  DropdownMenuItem(value: p.id, child: Text(p.displayName)),
              ],
              onChanged: controller.setPlatformFilter,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load platforms: $e'),
          ),
          if (showPlayers) ...[
            const SizedBox(height: 16),
            Text('Player count', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _PlayerCountStepper(
              label: 'Min',
              value: filters.minPlayers,
              onChanged: (v) => controller.setPlayerRange(
                minPlayers: v,
                maxPlayers: filters.maxPlayers,
              ),
            ),
            _PlayerCountStepper(
              label: 'Max',
              value: filters.maxPlayers,
              onChanged: (v) => controller.setPlayerRange(
                minPlayers: filters.minPlayers,
                maxPlayers: v,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single labelled +/- stepper for a player-count bound. A null value means
/// the bound is unset (no filter); the minimum a set bound can reach is 1, and
/// stepping below that clears it.
class _PlayerCountStepper extends StatelessWidget {
  const _PlayerCountStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value == null ? null : () => onChanged(value! <= 1 ? null : value! - 1),
        ),
        Text(value?.toString() ?? 'Any'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged((value ?? 0) + 1),
        ),
      ],
    );
  }
}
