import 'dart:convert';

import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/models/account_type.dart';
import 'package:family_budget/features/account/models/currency.dart';
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
    required bool isPersonal,
  }) async {
    try {
      final response = await _api.post(
        path: 'accounts',
        body: {'name': name, 'type': type.name, 'currency': currency.name.toUpperCase(), 'balance': balance, 'is_personal': isPersonal},
      );
      final Map<String, dynamic> data = response['data'];
      final account = Account.fromJson(data);
      final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');
      if (familyId != null) {
        await _cache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId');
      }

      return account;
    } catch (e, st) {
      _talker.error('AccountRepository: failed to create account', e, st);
      rethrow;
    }
  }

  Future<Account> update({
    required int id,
    String? name,
    AccountType? type,
  }) async {
    try {
      final response = await _api.put(
        path: 'accounts/$id',
        data: {'name': name, 'type': type!.name},
      );

      final Map<String, dynamic> data = response['data'];
      final account = Account.fromJson(data);
      final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');
      if (familyId != null) {
        await _cache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId');
      }

      return account;
    } catch (e, st) {
      _talker.error('AccountRepository: failed to update account id: $id', e, st);
      rethrow;
    }
  }

  Future<List<Account>> getList() async {
    final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');
    if (familyId == null) return [];

    final cachedRaw = await _cache.getRaw(namespace: 'accounts', key: 'user_accounts_family_$familyId') as String?;
    await _cache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId');

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

      await _cache.putRaw(
        namespace: 'accounts',
        key: 'user_accounts_family_$familyId',
        value: jsonEncode(data),
        ttl: const Duration(seconds: 30),
      );

      return data.map((model) => Account.fromJson(model as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _talker.error('FamilyRepository: failed to fetch families', e, st);
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _api.delete(path: 'accounts/$id');
      final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');
      if (familyId != null) {
        await _cache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId');
      }
    } catch (e, st) {
      _talker.error('AccountRepository: failed to delete accountId: $id}', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  return AccountRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(appCacheProvider));
}
