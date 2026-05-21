import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/models/account_type.dart';
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

  // Змінили тип повернення на Future<void>, бо ми не віддаємо рахунок назад,
  // а зберігаємо його всередині state
  Future<void> createAccount({
    required String name,
    required AccountType type,
    required Currency currency,
    required int balance,
    int? userId,
    int? familyId,
  }) async {
    // 1. Отримуємо поточний список рахунків (або пустий, якщо ще нічого немає)
    final previousState = state.value ?? [];

    // 2. Ставимо лоадер (якщо потрібно для UI)
    state = const AsyncLoading();

    try {
      // 3. Відправляємо запит на сервер
      final newAccount = await ref.read(accountRepositoryProvider).create(
        name: name, // Виправили пустий рядок!
        type: type,
        currency: currency,
        balance: balance,
        familyId: familyId,
        userId: userId,
      );

      // 4. Оновлюємо стейт: створюємо новий список (старі рахунки + новий рахунок)
      state = AsyncData([...previousState, newAccount]);

    } catch (e, st) {
      // 5. Якщо помилка — повертаємо старий стан, щоб UI не зламався,
      // і прокидаємо помилку далі, щоб віджет міг показати Snackbar
      state = AsyncData(previousState);
      rethrow;
    }
  }
}