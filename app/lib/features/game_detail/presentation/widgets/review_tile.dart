import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/review.dart';
import '../../application/game_detail_controller.dart';
import 'write_review_sheet.dart';

/// A single review on the game-detail screen. Shows the author, rating, and
/// body; spoiler bodies stay hidden behind a tap until revealed. The user's own
/// review gets edit/delete actions.
class ReviewTile extends ConsumerStatefulWidget {
  const ReviewTile({super.key, required this.gameId, required this.item, required this.isOwn});

  final String gameId;
  final ReviewWithAuthor item;
  final bool isOwn;

  @override
  ConsumerState<ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends ConsumerState<ReviewTile> {
  bool _spoilersRevealed = false;

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This removes your review from this game.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(gameDetailActionsProvider).deleteReview(widget.gameId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.item.review;
    final hidden = review.containsSpoilers && !_spoilersRevealed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('@${widget.item.authorUsername ?? widget.item.authorLabel}',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              if (review.rating != null)
                Text('${review.rating}/10', style: Theme.of(context).textTheme.bodySmall),
              if (widget.isOwn) ...[
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => WriteReviewSheet(gameId: widget.gameId, existing: review),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete',
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (hidden)
            InkWell(
              onTap: () => setState(() => _spoilersRevealed = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_off_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Contains spoilers — tap to show'),
                  ],
                ),
              ),
            )
          else
            Text(review.body),
        ],
      ),
    );
  }
}
