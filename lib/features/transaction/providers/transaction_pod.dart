import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:family_budget/features/transaction/models/transaction.dart';
import 'package:family_budget/features/transaction/models/transaction_type.dart';
import 'package:family_budget/features/transaction/repository/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_pod.g.dart';

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  @override
  FutureOr<List<Transaction>> build(int accountId) async {
    final repository = ref.watch(transactionRepositoryProvider);
    return await repository.getListByAccount(accountId);
  }

  Future<void> createTransaction({
    required TransactionType type,
    required int amount,
    required Currency currency,
    int? categoryId,
    int? targetAccountId,
    int? targetAmount,
    Currency? targetCurrency,
    String? description,
  }) async {
    final previousState = state.value ?? [];
    state = const AsyncLoading();

    try {
      final newTransaction = await ref
          .read(transactionRepositoryProvider)
          .create(
            type: type,
            amount: amount,
            accountId: accountId,
            currency: currency,
            categoryId: categoryId,
            targetAccountId: targetAccountId,
            targetAmount: targetAmount,
            targetCurrency: targetCurrency,
            description: description,
          );

      state = AsyncData([newTransaction, ...previousState]);

      ref.invalidate(accountProvider);

      if (targetAccountId != null) {
        ref.invalidate(transactionProvider(targetAccountId));
      }
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> updateTransaction({
    required int id,
    required TransactionType type,
    required int amount,
    required Currency currency,
    int? categoryId,
    int? targetAccountId,
    int? targetAmount,
    Currency? targetCurrency,
    String? description,
  }) async {
    final previousState = state.value ?? [];
    state = const AsyncLoading();

    try {
      final updatedTransaction = await ref
          .read(transactionRepositoryProvider)
          .update(
            id: id,
            type: type,
            amount: amount,
            accountId: accountId,
            currency: currency,
            categoryId: categoryId,
            targetAccountId: targetAccountId,
            targetAmount: targetAmount,
            targetCurrency: targetCurrency,
            description: description,
          );

      final newState = previousState.map((tx) {
        return tx.id == id ? updatedTransaction : tx;
      }).toList();

      state = AsyncData(newState);

      ref.invalidate(accountProvider);

      if (targetAccountId != null) {
        ref.invalidate(transactionProvider(targetAccountId));
      }
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final previousState = state.value ?? [];
    state = const AsyncLoading();

    try {
      await ref.read(transactionRepositoryProvider).delete(transaction);

      final newState = previousState.where((tx) => tx.id != transaction.id).toList();
      state = AsyncData(newState);

      ref.invalidate(accountProvider);

      if (transaction.targetAccountId != null) {
        ref.invalidate(transactionProvider(transaction.targetAccountId!));
      }
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }
}
