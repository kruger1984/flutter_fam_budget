import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/transaction_repository.dart';

part 'transaction_pod.g.dart';

@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  @override
  FutureOr<dynamic> build() async {
    return _fetchData();
  }

  Future<dynamic> _fetchData() async {
    final repository = ref.read(transactionRepositoryProvider);
    return null;
  }

  Future<void> performAction() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(transactionRepositoryProvider);
      state = AsyncData(await _fetchData());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}