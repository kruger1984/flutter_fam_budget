import 'package:family_budget/features/auth/providers/auth_provider.dart';
import 'package:family_budget/features/family/providers/family_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final family = ref.watch(familyProvider).value;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Користувач'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, color: Colors.blue)),
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),

          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: Text('Сім\'я: ${family?.name ?? 'Не вибрано'}'),
            subtitle: Text('Роль: ${family?.role.name ?? '...'}'),
            trailing: const Icon(Icons.swap_horiz),
            onTap: () {
              Navigator.pop(context);
              context.go('/gate');
              ref.read(familyProvider.notifier).clearActiveFamily();
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Управління рахунками'),
            onTap: () {
              // TODO: Перехід на екран налаштування рахунків
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Категорії транзакцій'),
            onTap: () {
              // TODO: Перехід на екран дерева категорій
              Navigator.pop(context);
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Налаштування'),
            onTap: () {
              // TODO: Перехід до налаштувань (тема, мова тощо)
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Вийти', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
