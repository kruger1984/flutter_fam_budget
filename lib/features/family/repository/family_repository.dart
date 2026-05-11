import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/family/models/famil_exception.dart';
import 'package:family_budget/features/family/models/family.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'family_repository.g.dart';

class FamilyRepository {
  FamilyRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  Future<Family> create(String name) async {
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

  Future<List<Family>> getList() async {
    final cachedRaw = await _cache.getRaw(namespace: 'families', key: 'user_families_list') as String?;

    if (cachedRaw != null) {
      try {
        final List<dynamic> cachedData = jsonDecode(cachedRaw);
        return cachedData.map((model) => Family.fromJson(model as Map<String, dynamic>)).toList();
      } catch (e) {
        _talker.warning('FamilyRepository: cached data is corrupted');
      }
    }

    try {
      _talker.debug('🏠 request get user families from API');
      final response = await _api.get(path: 'families');
      final List<dynamic> data = response['data'];

      await _cache.putRaw(namespace: 'families', key: 'user_families_list', value: jsonEncode(data), ttl: Duration(hours: 24));

      return data.map((model) => Family.fromJson(model as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _talker.error('FamilyRepository: failed to fetch families', e, st);
      rethrow;
    }
  }

  Future<Family> join(String code) async {
    try {
      final response = await _api.post(path: 'families/join', body: {'code': code});
      final Map<String, dynamic> data = response['data'];
      final family = Family.fromJson(data);

      await _cache.putRaw(namespace: 'auth', key: 'active_family_id', value: family.id.toString());
      await _cache.remove(namespace: 'families', key: 'user_families_list');

      return family;
    } on DioException catch (e) {
      if (e.response?.statusCode == 410) {
        throw InvalidInviteCodeException();
      }
      if (e.response?.statusCode == 422) {
        throw AlreadyInFamilyException();
      }

      _talker.error('FamilyRepository: failed to join family', e);
      throw UnknownFamilyException(e.message);
    } catch (e, st) {
      _talker.error('FamilyRepository: unexpected error', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FamilyRepository familyRepository(Ref ref) {
  return FamilyRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(appCacheProvider));
}
