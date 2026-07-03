import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/validation/username.dart';
import '../../../../data/repositories/profiles_repository.dart';
import '../../application/onboarding_controller.dart';

/// First real onboarding step: let the user replace the auto-generated username
/// (`name_xxxxxx`) with one of their own. Pre-filled with the current username;
/// "Next" is blocked until it is a valid, available name.
class OnboardingUsernameScreen extends ConsumerStatefulWidget {
  const OnboardingUsernameScreen({super.key});

  @override
  ConsumerState<OnboardingUsernameScreen> createState() => _OnboardingUsernameScreenState();
}

class _OnboardingUsernameScreenState extends ConsumerState<OnboardingUsernameScreen> {
  final _controller = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next(String currentUsername) async {
    final username = _controller.text.trim();
    final formatError = validateUsername(username);
    if (formatError != null) {
      setState(() => _error = formatError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Skip the write (and its uniqueness check against itself) if unchanged.
      if (username != currentUsername) {
        await ref.read(onboardingControllerProvider.notifier).saveUsername(username);
      }
      if (mounted) context.go(RoutePaths.onboardingLinkOrManual);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a username')),
      body: profileAsync.when(
        data: (profile) {
          final currentUsername = profile?.username ?? '';
          if (!_prefilled) {
            _controller.text = currentUsername;
            _prefilled = true;
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Pick a username others will see. You can change it later in your profile.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixText: '@',
                        errorText: _error,
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : () => _next(currentUsername),
                      child: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Next'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      ),
    );
  }
}
