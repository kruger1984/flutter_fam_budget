import 'package:freezed_annotation/freezed_annotation.dart';

enum SubscriptionPeriod {
  @JsonValue('p7D') p7D,
  @JsonValue('p1M') p1M,
  @JsonValue('p2M') p2M,
  @JsonValue('p3M') p3M,
  @JsonValue('p4M') p4M,
  @JsonValue('p6M') p6M,
  @JsonValue('p8M') p8M,
  @JsonValue('p1Y') p1Y;

  String get label => name.toUpperCase();
}

enum ValidationStatus {
  @JsonValue('active') active,
  @JsonValue('expired') expired,
  @JsonValue('canceled') canceled;
}