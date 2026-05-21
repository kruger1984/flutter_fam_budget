import 'dart:convert';

import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/models/account_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'account_repository.g.dart';

class AccountRepository {
  AccountRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  Future<Account> create({
    required String name,
    required AccountType type,
    required Currency currency,
    required int balance,
    int? userId,
    int? familyId,
  }) async {
    try {
      final response = await _api.post(path: 'accounts', body: {'name': name});
      final Map<String, dynamic> data = response['data'];
      final family = Account.fromJson(data);
      return family;
    } catch (e, st) {
      _talker.error('FamilyRepository: failed to create family', e, st);
      rethrow;
    }
  }

  Future<List<Account>> getList() async {
    final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');

    final cachedRaw = await _cache.getRaw(namespace: 'accounts', key: 'user_accounts_family_$familyId') as String?;

    if (cachedRaw != null) {
      try {
        final List<dynamic> cachedData = jsonDecode(cachedRaw);
        return cachedData.map((model) => Account.fromJson(model as Map<String, dynamic>)).toList();
      } catch (e) {
        _talker.warning('AccountRepository: cached data is corrupted');
      }
    }

    try {
      _talker.debug('🏠 request get user accounts from API');
      final response = await _api.get(path: 'accounts');
      final List<dynamic> data = response['data'];

      await _cache.putRaw(namespace: 'accounts', key: 'user_accounts_family_$familyId', value: jsonEncode(data), ttl: Duration(hours: 24));

      return data.map((model) => Account.fromJson(model as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _talker.error('FamilyRepository: failed to fetch families', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  return AccountRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(appCacheProvider));
}
