import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/friends_repository.dart';

/// Thin action facade over [FriendsRepository] that also invalidates the
/// affected providers so every friends-driven view (profile button, inbox,
/// feed) refreshes after a mutation. Widgets call these instead of touching the
/// repository + invalidation by hand.
class FriendActions {
  FriendActions(this._ref);

  final Ref _ref;

  FriendsRepository get _repo => _ref.read(friendsRepositoryProvider);

  Future<void> sendRequest(String addresseeId) async {
    await _repo.sendRequest(addresseeId);
    _invalidateFor(addresseeId);
  }

  Future<void> respond(String friendshipId, String otherUserId, {required bool accept}) async {
    await _repo.respondToRequest(friendshipId, accept: accept);
    _invalidateFor(otherUserId);
  }

  Future<void> cancel(String friendshipId, String otherUserId) async {
    await _repo.cancelRequest(friendshipId);
    _invalidateFor(otherUserId);
  }

  Future<void> remove(String friendshipId, String otherUserId) async {
    await _repo.removeFriend(friendshipId);
    _invalidateFor(otherUserId);
  }

  void _invalidateFor(String otherUserId) {
    // friendsProvider drives both the friends list and the feed (feedProvider
    // watches it), so invalidating it refreshes the feed too — no direct
    // dependency on the feed feature, keeping the import direction one-way.
    _ref.invalidate(incomingRequestsProvider);
    _ref.invalidate(outgoingRequestsProvider);
    _ref.invalidate(friendsProvider);
    _ref.invalidate(friendshipStatusProvider(otherUserId));
  }
}

final friendActionsProvider = Provider<FriendActions>((ref) => FriendActions(ref));
