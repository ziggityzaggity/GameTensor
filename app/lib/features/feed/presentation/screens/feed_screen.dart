import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../application/activity_item.dart';
import '../../application/feed_repository.dart';

/// Friends activity feed tab. Renders the merged, newest-first [ActivityItem]s
/// with the actor, an action phrase, and a tap-through to the target.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return AppShell(
      currentIndex: 3,
      title: 'Feed',
      body: feedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load feed: $e')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No activity yet. Add some friends to see what they log,\n'
                    'review, and list.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(feedProvider),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _ActivityTile(item: items[i]),
                ),
              ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final actorLabel = item.actor.displayName ?? item.actor.username;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: item.actor.avatarUrl != null
            ? NetworkImage(item.actor.avatarUrl!)
            : null,
        child: item.actor.avatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: _title(context, actorLabel),
      subtitle: _subtitle(),
      onTap: () => _openTarget(context),
    );
  }

  Widget _title(BuildContext context, String actor) {
    final (phrase, target) = switch (item) {
      GameLoggedActivity(:final game) => ('logged', game.canonicalName),
      ReviewWroteActivity(:final game) => ('reviewed', game.canonicalName),
      ListCreatedActivity(:final list) => ('created a list', list.title),
    };
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: actor, style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: ' $phrase '),
          TextSpan(text: target, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget? _subtitle() {
    final detail = switch (item) {
      GameLoggedActivity(:final liked) when liked == true => 'Liked it',
      GameLoggedActivity(:final liked) when liked == false => 'Disliked it',
      ReviewWroteActivity(:final rating) when rating != null =>
        'Rated ${rating.toStringAsFixed(1)}/10',
      _ => null,
    };
    return detail == null ? null : Text(detail);
  }

  void _openTarget(BuildContext context) {
    switch (item) {
      case GameLoggedActivity(:final game):
        context.push(RoutePaths.gameDetailPath(game.id));
      case ReviewWroteActivity(:final game):
        context.push(RoutePaths.gameDetailPath(game.id));
      case ListCreatedActivity(:final list):
        context.push(RoutePaths.listDetailPath(list.id));
    }
  }
}
