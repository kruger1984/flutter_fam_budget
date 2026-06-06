import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountProvider);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Мої рахунки', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          accountsState.when(
            data: (accounts) {
              if (accounts.isEmpty) return const Text('У вас ще немає рахунків');
              return Column(children: [
                ...accounts.map(
                      (account) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(account.name),
                          Text('${account.balance} ${account.currency.name}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
              ,
              );
            },
            error: (err, stack) => Center(child: Text('Помилка: $err')),
            loading: () => Center(child: CircularProgressIndicator()),
          )
        ],
      ),
    );
    //   },
    // );
  }
}
