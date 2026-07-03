import '../../../data/models/custom_list.dart';
import '../../../data/models/game.dart';
import '../../../data/models/profile.dart';

/// One entry in the friends activity feed. A sealed union over the three
/// activity kinds so each variant carries exactly the target it needs (a game
/// or a list) — no bag of nullable fields. Every variant shares an [actor]
/// (the friend who did it) and a [timestamp] used for the merged sort/cursor.
sealed class ActivityItem {
  const ActivityItem({required this.actor, required this.timestamp});

  /// The friend whose activity this is.
  final Profile actor;

  /// When it happened (the source row's updated_at/created_at), for time
  /// ordering and the before-timestamp pagination cursor.
  final DateTime timestamp;
}

/// A friend logged (or updated the log of) a game.
class GameLoggedActivity extends ActivityItem {
  const GameLoggedActivity({
    required super.actor,
    required super.timestamp,
    required this.game,
    this.liked,
    required this.completionStatusId,
  });

  final Game game;

  /// Thumbs up/down if the friend set one; null when unrated.
  final bool? liked;
  final int completionStatusId;
}

/// A friend wrote a review of a game.
class ReviewWroteActivity extends ActivityItem {
  const ReviewWroteActivity({
    required super.actor,
    required super.timestamp,
    required this.game,
    this.rating,
  });

  final Game game;

  /// The review's numeric rating (0-10) if given.
  final double? rating;
}

/// A friend created a list (public or friends-visibility).
class ListCreatedActivity extends ActivityItem {
  const ListCreatedActivity({
    required super.actor,
    required super.timestamp,
    required this.list,
  });

  final CustomList list;
}

/// Merges the per-source activity lists into a single newest-first feed and
/// caps it at [limit]. Kept pure (no I/O) so the merge/sort is unit-testable;
/// the repository fetches each source and calls this.
List<ActivityItem> mergeActivity(
  List<List<ActivityItem>> sources, {
  required int limit,
}) {
  final merged = <ActivityItem>[
    for (final source in sources) ...source,
  ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return merged.length > limit ? merged.sublist(0, limit) : merged;
}
