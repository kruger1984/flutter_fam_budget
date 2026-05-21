import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'transaction_repository.g.dart';

class TransactionRepository {
  TransactionRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  // TODO: add methods
}

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(
    ref.watch(apiClientProvider),
    ref.watch(talkerProvider),
    ref.watch(appCacheProvider),
  );
}