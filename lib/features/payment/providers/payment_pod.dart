import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/router/router_pod.dart';
import '../../../core/utils/talker_pod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payable_product.dart';
import '../models/payment_enums.dart';
import '../repository/payment_repository.dart';

part 'payment_pod.g.dart';

@Riverpod(keepAlive: true)
class PaymentController extends _$PaymentController {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  FutureOr<List<PayableProduct>> build() async {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        ref.read(talkerProvider).error('IAP Stream Error: $error');
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return _loadProducts();
  }

  Future<List<PayableProduct>> _loadProducts() async {
    final talker = ref.read(talkerProvider);

    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      talker.warning('IAP is not available on this device');
      return [];
    }

    final backendProducts = await ref.read(paymentRepositoryProvider).getPurchases(resetCache: true);

    if (backendProducts.isEmpty) return [];

    final productIds = backendProducts.map((e) => e.storeId).toSet();

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      talker.error('queryProductDetails Error: ${response.error}');
      return [];
    }

    final List<PayableProduct> payableProducts = [];
    for (final backendProduct in backendProducts) {
      try {
        final storeDetails = response.productDetails.firstWhere((pd) => pd.id == backendProduct.storeId);
        payableProducts.add(PayableProduct(storeProduct: backendProduct, productDetails: storeDetails));
      } catch (_) {
        talker.warning('Store did not return product: ${backendProduct.storeId}');
      }
    }

    return payableProducts;
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      ref.read(talkerProvider).error('Restore Purchases Error', e, st);
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    final talker = ref.read(talkerProvider);
    final repo = ref.read(paymentRepositoryProvider);

    for (var purchase in purchases) {
      talker.debug('IAP Status: ${purchase.status} | ID: ${purchase.productID}');

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        try {
          final result = await repo.checkSubscription(productId: purchase.productID, token: purchase.verificationData.serverVerificationData, resetCache: true);

          if (result.status == ValidationStatus.active) {
             talker.info('✅ Purchase successful and verified by server!');

            ref.read(authProvider.notifier).refreshUser();

            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }

            final isRestore = purchase.status == PurchaseStatus.restored;
            final message = isRestore ? 'Purchases successfully restored!' : 'Thank you for your purchase!';

            ref.read(routerProvider).go('/payment/thanks', extra: message);

          } else {
            talker.warning('⚠️ Server returned status: ${result.status}');
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
          }
        } catch (e, st) {
          talker.error('❌ Receipt validation error', e, st);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      } else if (purchase.status == PurchaseStatus.canceled || purchase.status == PurchaseStatus.error) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    }
  }
}
