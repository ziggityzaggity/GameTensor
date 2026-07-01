import 'package:flutter/material.dart';

import '../../../../data/models/game.dart';

class GameResultTile extends StatelessWidget {
  const GameResultTile({super.key, required this.game, required this.onTap});

  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: game.coverImageUrl != null ? NetworkImage(game.coverImageUrl!) : null,
        child: game.coverImageUrl == null ? const Icon(Icons.videogame_asset_outlined) : null,
      ),
      title: Text(game.canonicalName),
      subtitle: Text(game.kind == GameKind.videoGame ? 'Video game' : 'Tabletop game'),
      onTap: onTap,
    );
  }
}
