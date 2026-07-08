import 'dart:convert';

import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/cache/app_cache.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/transaction/models/transaction.dart';
import 'package:family_budget/features/transaction/models/transaction_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

part 'transaction_repository.g.dart';

class TransactionRepository {
  TransactionRepository(this._api, this._talker, this._cache);

  final ApiClient _api;
  final Talker _talker;
  final AppCache _cache;

  Future<void> _clearCache({required int accountId, int? targetAccountId}) async {
    final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');

    if (familyId != null) {
      await _cache.remove(namespace: 'transactions', key: 'family_$familyId');
      await _cache.remove(namespace: 'accounts', key: 'user_accounts_family_$familyId');
    }

    await _cache.remove(namespace: 'transactions', key: 'account_$accountId');

    if (targetAccountId != null) {
      await _cache.remove(namespace: 'transactions', key: 'account_$targetAccountId');
    }
  }

  Future<Transaction> create({
    required TransactionType type,
    required int amount,
    required int accountId,
    required Currency currency,
    int? categoryId,
    int? targetAccountId,
    int? targetAmount,
    Currency? targetCurrency,
    String? description,
  }) async {
    try {
      final response = await _api.post(
        path: 'transactions',
        body: {
          'type': type.name,
          'amount': amount,
          'account_id': accountId,
          'category_id': categoryId,
          'currency': currency.name.toUpperCase(),
          'target_account_id': targetAccountId,
          'target_amount': targetAmount,
          'target_currency': targetCurrency?.name.toUpperCase(),
          'description': description,
        },
      );
      final Map<String, dynamic> data = response['data'];
      final transaction = Transaction.fromJson(data);

      await _clearCache(accountId: accountId, targetAccountId: targetAccountId);

      return transaction;
    } catch (e, st) {
      _talker.error('TransactionRepository: failed to create transaction', e, st);
      rethrow;
    }
  }

  Future<Transaction> update({
    required int id,
    required TransactionType type,
    required int amount,
    required int accountId,
    required Currency currency,
    int? categoryId,
    int? targetAccountId,
    int? targetAmount,
    Currency? targetCurrency,
    String? description,
  }) async {
    try {
      final response = await _api.put(
        path: 'transactions/$id',
        data: {
          'type': type.name,
          'amount': amount,
          'account_id': accountId,
          'category_id': categoryId,
          'currency': currency.name.toUpperCase(),
          'target_account_id': targetAccountId,
          'target_amount': targetAmount,
          'target_currency': targetCurrency?.name.toUpperCase(),
          'description': description,
        },
      );

      final Map<String, dynamic> data = response['data'];
      final transaction = Transaction.fromJson(data);

      await _clearCache(accountId: accountId, targetAccountId: targetAccountId);

      return transaction;
    } catch (e, st) {
      _talker.error('TransactionRepository: failed to update transaction id: $id', e, st);
      rethrow;
    }
  }

  Future<List<Transaction>> getListByAccount(int accountId) async {
    final cacheKey = 'account_$accountId';
    final cachedRaw = await _cache.getRaw(namespace: 'transactions', key: cacheKey) as String?;

    if (cachedRaw != null) {
      try {
        final List<dynamic> cachedData = jsonDecode(cachedRaw);
        return cachedData.map((model) => Transaction.fromJson(model as Map<String, dynamic>)).toList();
      } catch (e) {
        _talker.warning('TransactionRepository: cached data is corrupted for account $accountId');
      }
    }

    try {
      _talker.debug('🏠 request get transactions for account $accountId from API');
      final response = await _api.get(path: 'transactions?account=$accountId');
      final List<dynamic> data = response['data'];

      await _cache.putRaw(
        namespace: 'transactions',
        key: cacheKey,
        value: jsonEncode(data),
        ttl: const Duration(minutes: 10),
      );

      return data.map((model) => Transaction.fromJson(model as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _talker.error('TransactionRepository: failed to fetch transactions for account', e, st);
      rethrow;
    }
  }

  Future<List<Transaction>> getList() async {
    final familyId = await _cache.getRaw(namespace: 'auth', key: 'active_family_id');

    if (familyId != null) {
      final cacheKey = 'family_$familyId';

      final cachedRaw = await _cache.getRaw(namespace: 'transactions', key: cacheKey) as String?;
      if (cachedRaw != null) {
        try {
          final List<dynamic> cachedData = jsonDecode(cachedRaw);
          return cachedData.map((model) => Transaction.fromJson(model as Map<String, dynamic>)).toList();
        } catch (e) {
          _talker.warning('TransactionRepository: cached data is corrupted');
        }
      }
    }

    try {
      _talker.debug('🏠 request get user transactions from API');
      final response = await _api.get(path: 'transactions');
      final List<dynamic> data = response['data'];

      if (familyId != null) {
        await _cache.putRaw(
          namespace: 'transactions',
          key: 'family_$familyId',
          value: jsonEncode(data),
          ttl: const Duration(minutes: 10),
        );
      }

      return data.map((model) => Transaction.fromJson(model as Map<String, dynamic>)).toList();
    } catch (e, st) {
      _talker.error('TransactionRepository: failed to fetch transactions', e, st);
      rethrow;
    }
  }

  Future<void> delete(Transaction transaction) async {
    try {
      await _api.delete(path: 'transactions/${transaction.id}');

      await _clearCache(accountId: transaction.accountId, targetAccountId: transaction.targetAccountId);
    } catch (e, st) {
      _talker.error('TransactionRepository: failed to delete transactionId: ${transaction.id}', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) {
  return TransactionRepository(ref.watch(apiClientProvider), ref.watch(talkerProvider), ref.watch(appCacheProvider));
}
