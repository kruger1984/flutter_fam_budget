import 'package:freezed_annotation/freezed_annotation.dart';

enum AccountType {
  @JsonValue('cash') cash,
  @JsonValue('card') card,
  @JsonValue('bank') bank,
}