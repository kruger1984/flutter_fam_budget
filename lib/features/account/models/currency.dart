import 'package:freezed_annotation/freezed_annotation.dart';

enum Currency {
  @JsonValue('UAH') uah,
  @JsonValue('USD') usd,
  @JsonValue('EUR') eur,
}