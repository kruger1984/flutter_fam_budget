import 'package:family_budget/features/auth/models/auth_session.dart';
import 'package:family_budget/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthHomeScreen extends ConsumerWidget {
  const AuthHomeScreen({super.key, this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final label = session?.user?.displayName ?? '🛠 Test';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              session?.user?.email ?? 'Ви не залогінені (сесія порожня)',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Відкрити екран Логіну'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: () => context.push('/payment'),
              icon: const Icon(Icons.payment),
              label: const Text('Відкрити екран Оплати'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(250, 50),
                backgroundColor: Colors.amber.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}