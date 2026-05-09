import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/family/models/family.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

import '../../../core/cache/app_cache.dart';

part 'family_repository.g.dart';

class FamilyRepository {
  FamilyRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  Future<Family> create(String name) async {
    _talker.debug('🏠 request create family');

    try {
      final response = await _api.post(path: 'families', body: {'name': name});

      final Map<String, dynamic> data = response['data'];
      final family = Family.fromJson(data);

      await _cache.putRaw(namespace: 'auth', key: 'active_family_id', value: family.id.toString());

      return family;

    } catch (e, st) {
      _talker.error('FamilyRepository: failed to create family', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FamilyRepository familyRepository(Ref ref) {
  return FamilyRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(appCacheProvider));
}
