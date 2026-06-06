import 'package:family_budget/features/account/models/account_type.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/account.dart';
import '../repository/account_repository.dart';

part 'account_pod.g.dart';

@riverpod
class AccountNotifier extends _$AccountNotifier {
  @override
  FutureOr<List<Account>> build() async {
    final repository = ref.watch(accountRepositoryProvider);
    return await repository.getList();
  }

  Future<void> createAccount({
    required String name,
    required AccountType type,
    required Currency currency,
    required int balance,
    required bool isPersonal,
  }) async {
    final previousState = state.value ?? [];

    state = const AsyncLoading();

    try {
      final newAccount = await ref.read(accountRepositoryProvider).create(name: name, type: type, currency: currency, balance: balance, isPersonal: isPersonal);

      state = AsyncData([...previousState, newAccount]);
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> updateAccount({
    required int id,
    String? name,
    AccountType? type,
  }) async {
    final previousState = state.value ?? [];

    state = const AsyncLoading();

    try {
      final updatedAccount = await ref.read(accountRepositoryProvider).update(id: id, name: name, type: type);

      final newState = previousState.map((account) {
        if (account.id == id) {
          return updatedAccount;
        }
        return account;
      }).toList();

      state = AsyncData(newState);
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }

  Future<void> deleteAccount(int accountId) async {
    final previousState = state.value ?? [];

    state = const AsyncLoading();

    try {
      await ref.read(accountRepositoryProvider).delete(accountId);

      final newState = previousState.where((acc) => acc.id != accountId).toList();
      state = AsyncData(newState);
    } catch (e) {
      state = AsyncData(previousState);
      rethrow;
    }
  }
}
