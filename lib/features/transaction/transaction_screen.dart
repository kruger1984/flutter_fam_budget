import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:family_budget/features/transaction/models/transaction_type.dart';
import 'package:family_budget/features/transaction/widgets/create_or_edit_transaction_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/extensions.dart';
import 'providers/transaction_pod.dart';

class TransactionScreen extends ConsumerWidget {
  final Account account;
  const TransactionScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionProvider(account.id));
    final accountsState = ref.watch(accountProvider);

    final currentAccount = accountsState.value?.firstWhere((a) => a.id == account.id, orElse: () => account) ?? account;

    return Scaffold(
      appBar: AppBar(
        title: Text('Транзакції: ${currentAccount.name}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: transactionsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Помилка: $err')),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(child: Text('Транзакцій ще немає'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isLast = index == transactions.length - 1;
                    final canEdit = isLast;

                    final dateStr = tx.createdAt?.toTime() ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.type.color.withAlpha(25),
                          child: Icon(
                            tx.type == TransactionType.income
                                ? Icons.arrow_downward
                                : tx.type == TransactionType.transfer
                                    ? Icons.swap_horiz
                                    : Icons.arrow_upward,
                            color: tx.type.color,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.category?.name ?? (tx.type == TransactionType.transfer ? 'Переказ' : 'Без категорії'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${tx.type.prefix}${tx.amount.toMoney(tx.currency)}',
                              style: TextStyle(
                                color: tx.type.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateStr),
                            if (tx.description != null && tx.description!.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    tx.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: canEdit
                            ? IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    // shape: const RoundedRectangleBorder(
                                    //   borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                    // ),
                                    builder: (context) => CreateOrEditTransactionSheet(transaction: tx, initialType: tx.type),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Поточний баланс:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        currentAccount.balance.toMoney(currentAccount.currency),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ActionButton(
                        label: 'Витрата',
                        icon: Icons.remove_circle_outline,
                        color: Colors.red,
                        onTap: () => _openSheet(context, TransactionType.expense),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Дохід',
                        icon: Icons.add_circle_outline,
                        color: Colors.green,
                        onTap: () => _openSheet(context, TransactionType.income),
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Переказ',
                        icon: Icons.swap_horiz,
                        color: Colors.blue,
                        onTap: () => _openSheet(context, TransactionType.transfer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context, TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreateOrEditTransactionSheet(initialType: type),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
