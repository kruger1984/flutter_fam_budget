import 'package:family_budget/features/account/models/account_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'currency.dart';

part 'account.freezed.dart';
part 'account.g.dart';

@freezed
abstract class Account with _$Account {
  const factory Account({
    required int id,
    required String name,
    required AccountType type,
    required Currency currency,
    required int balance,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'family_id') int? familyId,
    @JsonKey(name: 'is_personal') required bool isPersonal,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}
