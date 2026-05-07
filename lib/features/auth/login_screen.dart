import 'dart:io' show Platform;

import 'package:family_budget/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      if (!next.hasError || !context.mounted) return;
      if (prev?.error == next.error) return;
      final msg = next.error.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    });

    final authAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AutofillGroup(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(authAsync.isLoading),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: authAsync.isLoading ? null : () => _submit(false),
                child: authAsync.isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: authAsync.isLoading ? null : () => _loginWithGoogle(),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
              ),
              if (Platform.isIOS || Platform.isMacOS) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: authAsync.isLoading ? null : () => _loginWithApple(),
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(bool loading) async {
    if (loading) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).login(email: email, password: password);
  }

  Future<void> _loginWithGoogle() async {
    final authAsync = ref.read(authProvider);
    if (authAsync.isLoading) return;
    await ref.read(authProvider.notifier).loginWithGoogle();
  }

  Future<void> _loginWithApple() async {
    final authAsync = ref.read(authProvider);
    if (authAsync.isLoading) return;
    await ref.read(authProvider.notifier).loginWithApple();
  }
}
