import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/game_card.dart';
import '../../application/for_you_controller.dart';
import '../../data/recommendations_repository.dart';

/// Horizontal "For You" rail of personalized recommendations, shown on the
/// search screen's discover state (empty query). Tapping a card logs a
/// 'clicked' impression and opens the game; the close affordance logs
/// 'dismissed', which decays that game server-side and refreshes the rail.
class ForYouRail extends ConsumerWidget {
  const ForYouRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final railAsync = ref.watch(forYouRailProvider);

    return railAsync.when(
      // The rail is supplementary discover content: while loading (or on a
      // transient read failure) it simply takes no space instead of jumping.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recs) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('For You', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (recs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Log and rate a few games and personalized picks will show up here.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: recs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _RailCard(rec: recs[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailCard extends ConsumerWidget {
  const _RailCard({required this.rec});

  final RecommendedGame rec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(forYouActionsProvider);

    return SizedBox(
      width: 130,
      child: Stack(
        children: [
          Positioned.fill(
            child: GameCard(
              game: rec.game,
              onTap: () {
                // Fire-and-forget: navigation shouldn't wait on the impression.
                actions.recordClick(rec);
                context.push(RoutePaths.gameDetailPath(rec.game.id));
              },
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Tooltip(
              message: 'Not interested',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => actions.dismiss(rec),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
