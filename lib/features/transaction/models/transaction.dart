import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/transaction/models/transaction_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../account/models/currency.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required TransactionType type,
    required int amount,
    required Currency currency,
    @JsonKey(name: 'account_id') required int accountId,
    @JsonKey(name: 'category_id') int? categoryId,
    @JsonKey(name: 'target_account_id') int? targetAccountId,
    @JsonKey(name: 'target_amount') int? targetAmount,
    @JsonKey(name: 'target_currency') Currency? targetCurrency,
    @JsonKey(name: 'exchange_rate') double? exchangeRate,
    String? description,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    Account? account,
    Category? category,
    @JsonKey(name: 'target_account') Account? targetAccount,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}
