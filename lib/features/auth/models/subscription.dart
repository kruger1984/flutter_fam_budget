import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
abstract class Subscription with _$Subscription {
  const Subscription._();

  const factory Subscription({
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'expired_at', fromJson: _expiredAtFromJson)
    required DateTime expiredAt,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  bool get isActive => expiredAt.isAfter(DateTime.now());

  bool get isExpired => expiredAt.isBefore(DateTime.now());

  bool get isPremium => productId.contains('premium');

  bool get isStandard => productId.contains('standard');
}

DateTime _expiredAtFromJson(Object? value) =>
    DateTime.parse(value! as String).toLocal();
