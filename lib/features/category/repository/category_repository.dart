import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  CategoryRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  // TODO: add methods
}

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) {
  return CategoryRepository(
    ref.watch(apiClientProvider),
    ref.watch(talkerProvider),
    ref.watch(appCacheProvider),
  );
}