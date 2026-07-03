import 'package:freezed_annotation/freezed_annotation.dart';

part 'friendship.freezed.dart';
part 'friendship.g.dart';

enum FriendRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('declined')
  declined,
  @JsonValue('blocked')
  blocked,
}

/// A row in the `friendships` table. `requester_id` sent the request;
/// `addressee_id` receives/responds to it. The transition trigger (migration
/// 0010) only permits pending -> accepted|declined|blocked.
@freezed
class Friendship with _$Friendship {
  const factory Friendship({
    required String id,
    required String requesterId,
    required String addresseeId,
    @Default(FriendRequestStatus.pending) FriendRequestStatus status,
    required String createdAt,
    String? respondedAt,
  }) = _Friendship;

  factory Friendship.fromJson(Map<String, dynamic> json) =>
      _$FriendshipFromJson(json);
}

/// A pending friend request paired with the other party's public profile
/// fields, for the requests-inbox tiles. Built from a PostgREST embed of
/// `profiles` disambiguated by FK (requester_id/addressee_id); the profile row
/// may be absent if it isn't visible to the caller, so name fields are nullable.
class FriendRequest {
  const FriendRequest({
    required this.friendshipId,
    required this.otherUserId,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  /// Row id, used to accept/decline/cancel the request.
  final String friendshipId;

  /// The counterpart in the request (requester for an incoming request,
  /// addressee for an outgoing one) — the person whose profile the tile shows.
  final String otherUserId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  /// Best display label: display name, else username, else a fallback.
  String get label => displayName ?? username ?? 'Unknown';

  /// Parses a friendships row whose embed key holds the other party's profile.
  /// [embedKey] is `profiles!friendships_requester_id_fkey` for incoming
  /// requests and `profiles!friendships_addressee_id_fkey` for outgoing ones.
  factory FriendRequest.fromEmbed(
    Map<String, dynamic> row, {
    required String embedKey,
    required String otherIdKey,
  }) {
    final profile = row[embedKey] as Map<String, dynamic>?;
    return FriendRequest(
      friendshipId: row['id'] as String,
      otherUserId: row[otherIdKey] as String,
      username: profile?['username'] as String?,
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}

/// The caller's relationship to another user, driving which button the profile
/// screen renders. `outgoingPending`/`incomingPending` also carry the
/// friendship id so the button can cancel or respond without a second lookup.
sealed class FriendshipState {
  const FriendshipState();
}

class NoRelationship extends FriendshipState {
  const NoRelationship();
}

class OutgoingPending extends FriendshipState {
  const OutgoingPending(this.friendshipId);
  final String friendshipId;
}

class IncomingPending extends FriendshipState {
  const IncomingPending(this.friendshipId);
  final String friendshipId;
}

class AlreadyFriends extends FriendshipState {
  const AlreadyFriends(this.friendshipId);
  final String friendshipId;
}
