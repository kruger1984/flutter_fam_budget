import 'package:freezed_annotation/freezed_annotation.dart';

enum Currency {
  @JsonValue('uah') uah,
  @JsonValue('usd') usd,
  @JsonValue('eur') eur,
}