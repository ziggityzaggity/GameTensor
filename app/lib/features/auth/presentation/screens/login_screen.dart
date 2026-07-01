import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);
    if (failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authControllerProvider.notifier).signInWithApple(),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(RoutePaths.signup),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
