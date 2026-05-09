import 'package:family_budget/features/auth/models/subscription.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const User._();

  const factory User({
    @JsonKey(fromJson: _idFromJson) int? id,
    @JsonKey(name: 'name') @Default('') String name,
    @Default('en') String language,
    @Default('') String avatar,
    @Default('') String email,
    @Default('UTC') String timezone,
    @JsonKey(fromJson: _tryParseDate) DateTime? birthday,
    Subscription? subscription,
    @JsonKey(name: 'created_at', fromJson: _parseDateLocalNullable) DateTime? createdAt,
    @JsonKey(name: 'updated_at', fromJson: _parseDateLocalNullable) DateTime? updatedAt,
  }) = _AppUser;

  factory User.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);

  bool hasActiveSubscription() => subscription?.isActive ?? false;

  bool get hasActivePremiumSubscription {
    if (!hasActiveSubscription()) return false;
    return subscription?.isPremium ?? false;
  }

  bool get hasActiveStandardSubscription {
    if (!hasActiveSubscription()) return false;
    return subscription?.isStandard ?? false;
  }
}

int? _idFromJson(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _tryParseDate(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

// DateTime? _tryParseDateLocal(Object? value) {
//   if (value == null) return null;
//   if (value is String) return DateTime.tryParse(value)?.toLocal();
//   return null;
// }

DateTime? _parseDateLocalNullable(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.parse(value).toLocal();
  return null;
}
