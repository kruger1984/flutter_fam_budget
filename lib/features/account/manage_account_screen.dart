import 'package:family_budget/core/services/notification_service.dart';
import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:family_budget/features/account/widgets/create_or_edit_account_sheet.dart';
import 'package:family_budget/features/auth/providers/auth_provider.dart';
import 'package:family_budget/features/family/providers/family_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/extensions.dart';

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final accountsState = ref.watch(accountProvider);
    final notifier = ref.read(notificationServiceProvider);
    final family = ref.read(familyProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Управління рахунками'), centerTitle: true),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => const CreateOrEditAccountSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Додати рахунок'),
      ),

      body: accountsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Помилка: $err')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const Center(child: Text('Немає рахунків для управління'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];

              final isOwner = family?.owner.id == currentUser!.id;

              return Dismissible(
                key: ValueKey(account.id),
                direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,

                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Видалити рахунок?'),
                        content: Text('Ви впевнені, що хочете видалити рахунок "${account.name}"? Цю дію неможливо скасувати.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Скасувати')),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Видалити'),
                          ),
                        ],
                      );
                    },
                  );
                },

                onDismissed: (direction) async {
                  try {
                    await ref.read(accountProvider.notifier).deleteAccount(account.id);
                    if (context.mounted) {
                      notifier.showSuccess(context: context, title: 'Рахунок видалено');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      notifier.showError(context: context, title: 'Помилка: $e');
                    }
                  }
                },

                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(account.name),
                    subtitle: Text(account.balance.toMoney(account.currency)),
                    leading: Icon(account.isPersonal ? Icons.person : Icons.family_restroom, color: isOwner ? Colors.blue : Colors.grey),
                    trailing: isOwner
                        ? IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => CreateOrEditAccountSheet(account: account),
                              );
                            },
                          )
                        : const Tooltip(
                            message: 'Редагувати може тільки власник',
                            child: Icon(Icons.lock_outline, color: Colors.grey),
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
