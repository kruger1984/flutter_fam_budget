import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'payment_enums.dart';

part 'store_product.freezed.dart';
part 'store_product.g.dart';

@freezed
abstract class StoreProduct with _$StoreProduct {
  const StoreProduct._();

  const factory StoreProduct({
    @JsonKey(name: 'apple_subscription_id') required String appleSubscriptionId,
    @JsonKey(name: 'google_subscription_id') required String androidSubscriptionId,
    required SubscriptionPeriod period,
  }) = _StoreProduct;

  factory StoreProduct.fromJson(Map<String, dynamic> json) =>
      _$StoreProductFromJson(json);

  String get storeId => Platform.isAndroid ? androidSubscriptionId : appleSubscriptionId;

  bool get isPremium => storeId.contains('premium');
  bool get isStandard => storeId.contains('standard');
}