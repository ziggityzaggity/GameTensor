import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../search/application/search_controller.dart';
import '../../application/onboarding_controller.dart';

class OnboardingManualAddScreen extends ConsumerStatefulWidget {
  const OnboardingManualAddScreen({super.key});

  @override
  ConsumerState<OnboardingManualAddScreen> createState() => _OnboardingManualAddScreenState();
}

class _OnboardingManualAddScreenState extends ConsumerState<OnboardingManualAddScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final selections = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add games you\'ve played')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search for a game...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (q) => ref.read(searchControllerProvider.notifier).search(q),
            ),
          ),
          if (searchState.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: searchState.results.length,
              itemBuilder: (context, index) {
                final game = searchState.results[index];
                final selected = ref.read(onboardingControllerProvider.notifier).isSelected(game.id);
                return CheckboxListTile(
                  title: Text(game.canonicalName),
                  value: selected,
                  onChanged: (_) => ref.read(onboardingControllerProvider.notifier).toggleGame(game),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: selections.isEmpty ? null : () => context.go(RoutePaths.onboardingRateGames),
              child: Text('Next (${selections.length} selected)'),
            ),
          ),
        ],
      ),
    );
  }
}
