import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../data/models/friendship.dart';
import '../../../../data/repositories/friends_repository.dart';
import '../../application/friend_actions.dart';

/// Context-sensitive friend button shown on another user's profile. It reflects
/// the current [FriendshipState] and drives the matching action, invalidating
/// providers (via [FriendActions]) so the button updates after each tap.
class FriendButton extends ConsumerWidget {
  const FriendButton({super.key, required this.userId});

  /// The profile owner's id (never the caller's — the profile screen hides this
  /// button on your own profile).
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(friendshipStatusProvider(userId));
    return statusAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Couldn\'t load friend status: $e'),
      data: (state) => _buttonsFor(context, ref, state),
    );
  }

  Widget _buttonsFor(BuildContext context, WidgetRef ref, FriendshipState state) {
    final actions = ref.read(friendActionsProvider);
    switch (state) {
      case NoRelationship():
        return FilledButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Add friend'),
          onPressed: () => _run(context, () => actions.sendRequest(userId)),
        );
      case OutgoingPending(:final friendshipId):
        return OutlinedButton.icon(
          icon: const Icon(Icons.hourglass_top),
          label: const Text('Requested'),
          onPressed: () =>
              _run(context, () => actions.cancel(friendshipId, userId)),
        );
      case IncomingPending(:final friendshipId):
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _run(
                  context, () => actions.respond(friendshipId, userId, accept: true)),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _run(
                  context, () => actions.respond(friendshipId, userId, accept: false)),
              child: const Text('Decline'),
            ),
          ],
        );
      case AlreadyFriends(:final friendshipId):
        return OutlinedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Friends'),
          onPressed: () => _confirmRemove(context, ref, friendshipId),
        );
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, String friendshipId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove friend?'),
        content: const Text('You will no longer see each other in the feed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context,
        () => ref.read(friendActionsProvider).remove(friendshipId, userId));
  }

  /// Runs a friend mutation, surfacing a [ValidationFailure] as a snackbar
  /// (e.g. "there is already a request between you two") rather than a crash.
  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } on ValidationFailure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message)));
      }
    }
  }
}
