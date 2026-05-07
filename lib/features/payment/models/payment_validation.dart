import 'package:freezed_annotation/freezed_annotation.dart';
import 'payment_enums.dart';

part 'payment_validation.freezed.dart';
part 'payment_validation.g.dart';

@freezed
abstract class PaymentValidation with _$PaymentValidation {
  const factory PaymentValidation({
    required ValidationStatus status,
    @JsonKey(name: 'expiry_date') required DateTime expiryDate,
    @JsonKey(name: 'product_id') required String productId,
  }) = _PaymentValidation;

  factory PaymentValidation.fromJson(Map<String, dynamic> json) =>
      _$PaymentValidationFromJson(json);
}