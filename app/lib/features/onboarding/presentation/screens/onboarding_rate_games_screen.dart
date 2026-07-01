import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../application/onboarding_controller.dart';

const _completionStatuses = [
  (id: 1, label: 'Not Started'),
  (id: 2, label: 'Playing'),
  (id: 4, label: 'Dropped'),
  (id: 5, label: 'Completed (Main Story)'),
  (id: 6, label: '100% Complete'),
];

class OnboardingRateGamesScreen extends ConsumerWidget {
  const OnboardingRateGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final selections = ref.watch(onboardingControllerProvider);
    final games = notifier.selectedGames;

    return Scaffold(
      appBar: AppBar(title: const Text('Rate what you\'ve played')),
      body: ListView.builder(
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          final selection = selections[game.id];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.canonicalName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _completionStatuses
                        .map((s) => ChoiceChip(
                              label: Text(s.label),
                              selected: selection?.completionStatusId == s.id,
                              onSelected: (_) => notifier.setCompletionStatus(game.id, s.id),
                            ))
                        .toList(),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_up,
                            color: selection?.liked == true ? Colors.green : null),
                        onPressed: () =>
                            notifier.setLiked(game.id, selection?.liked == true ? null : true),
                      ),
                      IconButton(
                        icon: Icon(Icons.thumb_down,
                            color: selection?.liked == false ? Colors.red : null),
                        onPressed: () =>
                            notifier.setLiked(game.id, selection?.liked == false ? null : false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () async {
            await notifier.submitAndCompleteOnboarding();
            // Triggers go_router's redirect to re-evaluate now that
            // onboarding_completed_at is set, releasing the user into the main app.
            if (context.mounted) context.go(RoutePaths.search);
          },
          child: const Text('Finish setup'),
        ),
      ),
    );
  }
}
