import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/game_detail_controller.dart';
import '../widgets/log_status_sheet.dart';
import '../widgets/review_tile.dart';
import '../widgets/write_review_sheet.dart';

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));
    final reviewsAsync = ref.watch(gameReviewsProvider(gameId));
    final myLogAsync = ref.watch(myGameLogProvider(gameId));
    final currentUserId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(gameAsync.valueOrNull?.canonicalName ?? 'Game')),
      body: gameAsync.when(
        data: (game) {
          if (game == null) return const Center(child: Text('Game not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (game.coverImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(game.coverImageUrl!, height: 220, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(game.canonicalName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              if (game.summary != null) Text(game.summary!),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => LogStatusSheet(gameId: gameId, existingLog: myLogAsync.valueOrNull),
                    ),
                    child: const Text('Log / rate'),
                  ),
                  OutlinedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => WriteReviewSheet(gameId: gameId),
                    ),
                    child: const Text('Write a review'),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
              reviewsAsync.when(
                data: (reviews) => reviews.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No reviews yet.'),
                      )
                    : Column(
                        children: reviews
                            .map((r) => ReviewTile(
                                  gameId: gameId,
                                  item: r,
                                  isOwn: r.review.userId == currentUserId,
                                ))
                            .toList(),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Text('Failed to load reviews: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load game: $e')),
      ),
    );
  }
}
