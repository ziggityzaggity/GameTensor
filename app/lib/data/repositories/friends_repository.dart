import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap.dart';
import '../../core/errors/failure.dart';
import '../models/friendship.dart';
import '../models/profile.dart';
import 'profiles_repository.dart';

/// All friendship queries and mutations. Every call runs under the caller's
/// JWT, so RLS (policies in 0007/0010) governs what is readable and writable —
/// this repository only shapes the queries; it never bypasses the boundary.
class FriendsRepository {
  FriendsRepository(this._client);

  final SupabaseClient _client;

  // Postgres unique-violation code, raised by both the same-direction
  // (requester_id, addressee_id) constraint and the reverse-direction
  // friendships_pair_uniq index (migration 0010).
  static const _uniqueViolation = '23505';

  // FK-disambiguated embeds: friendships references profiles twice, so a bare
  // `profiles(...)` embed is ambiguous (PostgREST PGRST201). These name the FK.
  static const _requesterProfile =
      'profiles!friendships_requester_id_fkey(id, username, display_name, avatar_url)';
  static const _addresseeProfile =
      'profiles!friendships_addressee_id_fkey(id, username, display_name, avatar_url)';

  // For friends() both FK paths point at the same table, so they must be
  // aliased or PostgREST collides them (error 42712, "table name specified more
  // than once"). The alias also becomes the JSON key we read below.
  static const _requesterProfileAliased =
      'requester:profiles!friendships_requester_id_fkey(id, username, display_name, avatar_url)';
  static const _addresseeProfileAliased =
      'addressee:profiles!friendships_addressee_id_fkey(id, username, display_name, avatar_url)';

  /// Sends a friend request to [addresseeId]. The RLS insert policy requires
  /// requester_id = self, so that is set here (not passed in).
  ///
  /// Throws [ValidationFailure] on either unique violation — an already-sent
  /// request (same direction) or a pending request in the reverse direction
  /// (the other user already asked you) — so the UI shows a friendly message
  /// instead of a raw 409/500.
  Future<void> sendRequest(String addresseeId) async {
    final self = _requireSelf();
    if (addresseeId == self) {
      throw const ValidationFailure("You can't friend yourself");
    }
    try {
      await _client.from('friendships').insert({
        'requester_id': self,
        'addressee_id': addresseeId,
      });
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolation) {
        throw const ValidationFailure('There is already a request between you two');
      }
      rethrow;
    }
  }

  /// Accepts or declines an incoming request. RLS restricts UPDATE to the
  /// addressee and the transition trigger enforces pending -> accepted|declined,
  /// so a requester (or a non-pending row) simply matches no rows / raises.
  Future<void> respondToRequest(String friendshipId, {required bool accept}) async {
    await _client.from('friendships').update({
      'status': accept ? 'accepted' : 'declined',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);
  }

  /// Cancels a request you sent, or removes an existing friendship. The RLS
  /// delete policy lets either party delete, so both cases are one delete.
  Future<void> cancelRequest(String friendshipId) => removeFriend(friendshipId);

  Future<void> removeFriend(String friendshipId) async {
    await _client.from('friendships').delete().eq('id', friendshipId);
  }

  /// Pending requests addressed to the caller, each with the requester's
  /// profile embedded for the inbox tile.
  Future<List<FriendRequest>> incomingRequests() async {
    final self = _requireSelf();
    final rows = await _client
        .from('friendships')
        .select('id, requester_id, $_requesterProfile')
        .eq('addressee_id', self)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows
        .map((r) => FriendRequest.fromEmbed(
              r,
              embedKey: 'profiles',
              otherIdKey: 'requester_id',
            ))
        .toList();
  }

  /// Pending requests the caller sent, each with the addressee's profile.
  Future<List<FriendRequest>> outgoingRequests() async {
    final self = _requireSelf();
    final rows = await _client
        .from('friendships')
        .select('id, addressee_id, $_addresseeProfile')
        .eq('requester_id', self)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return rows
        .map((r) => FriendRequest.fromEmbed(
              r,
              embedKey: 'profiles',
              otherIdKey: 'addressee_id',
            ))
        .toList();
  }

  /// The caller's accepted friends. Queries `friendships` directly (not
  /// `friend_edges`) with an OR over both directions and embeds BOTH profile
  /// sides, then picks whichever party isn't the caller. This is one round trip
  /// and carries the friendship id (needed for removeFriend) plus the friend's
  /// profile — `friend_edges` has neither the id nor profile columns.
  Future<List<FriendRequest>> friends() async {
    final self = _requireSelf();
    final rows = await _client
        .from('friendships')
        .select(
            'id, requester_id, addressee_id, $_requesterProfileAliased, $_addresseeProfileAliased')
        .eq('status', 'accepted')
        .or('requester_id.eq.$self,addressee_id.eq.$self')
        .order('responded_at', ascending: false);
    return rows.map((r) {
      final selfIsRequester = r['requester_id'] == self;
      // The friend is the party that isn't the caller (the aliased embed key).
      return FriendRequest.fromEmbed(
        r,
        embedKey: selfIsRequester ? 'addressee' : 'requester',
        otherIdKey: selfIsRequester ? 'addressee_id' : 'requester_id',
      );
    }).toList();
  }

  /// The caller's relationship to [otherUserId], in one query, so the profile
  /// screen can render the right button. Fetches the single friendship row in
  /// either direction and maps its status/direction to a [FriendshipState].
  Future<FriendshipState> friendshipStatusWith(String otherUserId) async {
    final self = _requireSelf();
    final row = await _client
        .from('friendships')
        .select('id, requester_id, addressee_id, status')
        .or('and(requester_id.eq.$self,addressee_id.eq.$otherUserId),'
            'and(requester_id.eq.$otherUserId,addressee_id.eq.$self)')
        .maybeSingle();
    if (row == null) return const NoRelationship();

    final id = row['id'] as String;
    final status = row['status'] as String;
    if (status == 'accepted') return AlreadyFriends(id);
    if (status == 'pending') {
      return row['requester_id'] == self
          ? OutgoingPending(id)
          : IncomingPending(id);
    }
    // declined/blocked read as no active relationship for button purposes.
    return const NoRelationship();
  }

  String _requireSelf() {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AuthFailure('You must be signed in');
    }
    return id;
  }
}

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(supabase);
});

final incomingRequestsProvider = FutureProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendsRepositoryProvider).incomingRequests();
});

final outgoingRequestsProvider = FutureProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendsRepositoryProvider).outgoingRequests();
});

final friendsProvider = FutureProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendsRepositoryProvider).friends();
});

/// Relationship state with a specific user, keyed by their id.
final friendshipStatusProvider =
    FutureProvider.family<FriendshipState, String>((ref, otherUserId) {
  return ref.watch(friendsRepositoryProvider).friendshipStatusWith(otherUserId);
});

/// Search other users by username prefix for the find-friends field.
final userSearchProvider =
    FutureProvider.family<List<Profile>, String>((ref, prefix) {
  final trimmed = prefix.trim();
  if (trimmed.isEmpty) return Future.value(const []);
  return ref.read(profilesRepositoryProvider).searchByUsername(trimmed);
});
