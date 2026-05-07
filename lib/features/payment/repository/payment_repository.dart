import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:family_budget/core/cache/cache_pods.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/http_pod.dart';
import '../../../core/cache/app_cache.dart';
import '../../../core/utils/talker_pod.dart';
import '../models/store_product.dart';
import '../models/payment_validation.dart';

part 'payment_repository.g.dart';

class PaymentRepository {
  PaymentRepository({
    required ApiClient api,
    required AppCache cache,
    required Talker talker,
  })  : _api = api,
        _cache = cache,
        _talker = talker;

  final ApiClient _api;
  final AppCache _cache;
  final Talker _talker;

  static const _purchaseNamespace = 'payment_purchase';
  static const _checkNamespace = 'payment_check';

  Future<List<StoreProduct>> getPurchases({
    int page = 0,
    int limit = 99,
    bool resetCache = false,
  }) async {
    final key = '${page}_$limit';

    if (resetCache) {
      await _cache.remove(namespace: _purchaseNamespace, key: key);
    }

    _talker.debug('🤑 request products (Purchases) with cache');

    return await _cache.rememberJson<List<StoreProduct>>(
      namespace: _purchaseNamespace,
      key: key,
      ttl: const Duration(hours: 3),
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        final items = map['items'] as List<dynamic>? ?? [];
        return items.map((e) => StoreProduct.fromJson(e as Map<String, dynamic>)).toList();
      },
      fetchJson: () async {

        return await _api.get(
          path: 'purchases',
          queryParameters: {'page': page, 'limit': limit, 'filter[is_active]': 1},
        );
      },
    );
  }

  Future<PaymentValidation> checkSubscription({
    required String productId,
    required String token,
    bool resetCache = false,
  }) async {
    final hashedToken = md5.convert(utf8.encode(token)).toString();
    final key = 'check_${productId}_$hashedToken';

    if (resetCache) {
      await _cache.remove(namespace: _checkNamespace, key: key);
    }

    return await _cache.rememberJson<PaymentValidation>(
      namespace: _checkNamespace,
      key: key,
      ttl: const Duration(minutes: 180),
      fromJson: (json) => PaymentValidation.fromJson(json as Map<String, dynamic>),
      fetchJson: () async {
        return await _api.post(
          path: 'subscriptions/check',
          body: {
            'product_id': productId,
            'purchase_token': token,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          },
        );
      },
    );
  }

  Future<bool> applyCoupon({required String code}) async {
    try {
      await _api.post(
        path: 'users/subscriptions/coupon',
        body: {'code': code},
      );
      return true;
    } catch (e, st) {
      _talker.error('Error code activating: $code', e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(appCacheProvider),
    talker: ref.watch(talkerProvider),
  );
}