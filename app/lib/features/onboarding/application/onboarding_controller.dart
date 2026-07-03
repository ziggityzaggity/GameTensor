import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/game.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/game_logs_repository.dart';
import '../../../data/repositories/profiles_repository.dart';

class OnboardingSelection {
  const OnboardingSelection({this.completionStatusId = 5, this.liked});
  final int completionStatusId;
  final bool? liked;

  OnboardingSelection copyWith({int? completionStatusId, bool? liked}) {
    return OnboardingSelection(
      completionStatusId: completionStatusId ?? this.completionStatusId,
      liked: liked ?? this.liked,
    );
  }
}

/// Holds the games the user picked in `onboarding_manual_add_screen` and their
/// per-game like/dislike + completion status from `onboarding_rate_games_screen`,
/// until the whole batch is submitted at the end of the flow.
class OnboardingController extends Notifier<Map<String, OnboardingSelection>> {
  final Map<String, Game> _selectedGames = {};

  @override
  Map<String, OnboardingSelection> build() => {};

  List<Game> get selectedGames => _selectedGames.values.toList();

  void toggleGame(Game game) {
    if (_selectedGames.containsKey(game.id)) {
      _selectedGames.remove(game.id);
      state = {...state}..remove(game.id);
    } else {
      _selectedGames[game.id] = game;
      state = {...state, game.id: const OnboardingSelection()};
    }
  }

  bool isSelected(String gameId) => _selectedGames.containsKey(gameId);

  void setCompletionStatus(String gameId, int completionStatusId) {
    final current = state[gameId] ?? const OnboardingSelection();
    state = {...state, gameId: current.copyWith(completionStatusId: completionStatusId)};
  }

  void setLiked(String gameId, bool? liked) {
    final current = state[gameId] ?? const OnboardingSelection();
    state = {...state, gameId: current.copyWith(liked: liked)};
  }

  /// Persists the username chosen in the onboarding username step. Throws a
  /// [Failure] (e.g. duplicate) that the screen surfaces; the router's
  /// onboarding gate keeps the user in the flow until the final step.
  Future<void> saveUsername(String username) async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;
    await ref.read(profilesRepositoryProvider).updateProfile(userId, username: username);
    ref.invalidate(currentProfileProvider);
  }

  Future<void> submitAndCompleteOnboarding() async {
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    final entries = state.entries
        .map((e) => {
              'gameId': e.key,
              'completionStatusId': e.value.completionStatusId,
              'liked': e.value.liked,
            })
        .toList();

    if (entries.isNotEmpty) {
      await ref.read(gameLogsRepositoryProvider).batchUpsertLogs(userId, entries);
    }
    await ref.read(profilesRepositoryProvider).completeOnboarding(userId);
    ref.invalidate(currentProfileProvider);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, Map<String, OnboardingSelection>>(OnboardingController.new);
