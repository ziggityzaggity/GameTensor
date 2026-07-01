import 'package:flutter/material.dart';

import '../../data/models/game.dart';

class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, this.onTap});

  final Game game;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: game.coverImageUrl != null
                  ? Image.network(game.coverImageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.videogame_asset_outlined, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                game.canonicalName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
