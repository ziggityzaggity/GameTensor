import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';

class OnboardingLinkOrManualScreen extends StatelessWidget {
  const OnboardingLinkOrManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get set up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Xbox linking ships in Phase 2 (official XSTS API); shown here as a
              // disabled stub so the onboarding layout doesn't need to change later.
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.sports_esports),
                label: const Text('Link Xbox account (coming soon)'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go(RoutePaths.onboardingManualAdd),
                icon: const Icon(Icons.edit),
                label: const Text('Add games manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
