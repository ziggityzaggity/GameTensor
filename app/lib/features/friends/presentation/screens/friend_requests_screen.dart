import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../data/repositories/friends_repository.dart';
import '../../application/friend_actions.dart';
import '../widgets/friend_request_tile.dart';

/// Friends hub: a username search to find people, the incoming requests to
/// accept/decline, and the outgoing requests to cancel. Reachable from the
/// profile screen. Pushed (not a tab) so it keeps a back button.
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingRequestsProvider);
    final outgoing = ref.watch(outgoingRequestsProvider);
    final actions = ref.read(friendActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView(
        children: [
          _SearchField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
          ),
          if (_query.trim().isNotEmpty)
            _SearchResults(query: _query.trim())
          else ...[
            const _SectionHeader('Requests received'),
            incoming.when(
              loading: () => const _Loading(),
              error: (e, _) => _Error('$e'),
              data: (requests) => requests.isEmpty
                  ? const _Empty('No incoming requests')
                  : Column(
                      children: [
                        for (final r in requests)
                          FriendRequestTile(
                            request: r,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Accept',
                                  onPressed: () => actions.respond(
                                      r.friendshipId, r.otherUserId, accept: true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Decline',
                                  onPressed: () => actions.respond(
                                      r.friendshipId, r.otherUserId, accept: false),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const _SectionHeader('Requests sent'),
            outgoing.when(
              loading: () => const _Loading(),
              error: (e, _) => _Error('$e'),
              data: (requests) => requests.isEmpty
                  ? const _Empty('No pending sent requests')
                  : Column(
                      children: [
                        for (final r in requests)
                          FriendRequestTile(
                            request: r,
                            trailing: TextButton(
                              onPressed: () =>
                                  actions.cancel(r.friendshipId, r.otherUserId),
                              child: const Text('Cancel'),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Find people by username',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(userSearchProvider(query));
    return results.when(
      loading: () => const _Loading(),
      error: (e, _) => _Error('$e'),
      data: (profiles) => profiles.isEmpty
          ? const _Empty('No users found')
          : Column(
              children: [
                for (final p in profiles)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                      child: p.avatarUrl == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(p.displayName ?? p.username),
                    subtitle: Text('@${p.username}'),
                    onTap: () => context.push(RoutePaths.profilePath(p.username)),
                  ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Something went wrong: $message'),
      );
}
