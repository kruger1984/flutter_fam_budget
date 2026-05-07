import 'package:dio/dio.dart';
import 'package:family_budget/core/api/api_client.dart';
import 'package:family_budget/core/api/http_pod.dart';
import 'package:family_budget/core/providers/bootstrap_providers.dart';
import 'package:family_budget/core/utils/talker_pod.dart';
import 'package:family_budget/features/payment/models/payment_enums.dart';
import 'package:family_budget/features/payment/repository/payment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getPurchases fetches and parses products correctly', () async {
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'));
    final dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true));

    dioAdapter.onGet('purchases', (server) {
      return server.reply(200, {
        'items': [
          {'apple_subscription_id': 'premium_ios', 'google_subscription_id': 'premium_android', 'period': 'p1M'},
        ],
      });
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWith((ref) {
          return ApiClient(dio, talker: ref.watch(talkerProvider));
        }),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(paymentRepositoryProvider);
    final products = await repository.getPurchases(resetCache: true);

    expect(products.length, 1);
    expect(products.first.appleSubscriptionId, 'premium_ios');
    expect(products.first.period, SubscriptionPeriod.p1M);
    expect(products.first.isPremium, isTrue);
  });

  test('checkSubscription returns validation status', () async {
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'));
    final dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true));

    dioAdapter.onPost('subscriptions/check', (server) {
      return server.reply(200, {'status': 'active', 'expiry_date': '2026-12-31T23:59:59.000Z', 'product_id': 'premium_ios'});
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWith((ref) {
          return ApiClient(dio, talker: ref.watch(talkerProvider));
        }),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(paymentRepositoryProvider);
    final validation = await repository.checkSubscription(productId: 'premium_ios', token: 'fake_receipt_token', resetCache: true);

    expect(validation.status, ValidationStatus.active);
    expect(validation.productId, 'premium_ios');
    expect(validation.expiryDate.year, 2026);
  });

  test('applyCoupon completes successfully on 200 OK', () async {
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/'));
    final dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher(matchMethod: true));

    dioAdapter.onPost('users/subscriptions/coupon', (server) {
      return server.reply(200, {'message': 'Coupon applied'});
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiClientProvider.overrideWith((ref) {
          return ApiClient(dio, talker: ref.watch(talkerProvider));
        }),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(paymentRepositoryProvider);
    final result = await repository.applyCoupon(code: 'PROMO_CODE');

    expect(result, isTrue);
  });
}
