import 'package:intl/intl.dart';

import '../../features/account/models/currency.dart';

extension DateTimeFormatting on DateTime {
  String toShortDate() {
    return DateFormat('dd.MM.yyyy').format(this);
  }

  String toTime() {
    return DateFormat('HH:mm').format(this);
  }
}

extension MoneyFormat on int {
  String toMoney(Currency currency) {
    final amount = this / 100;
    return '${amount.toStringAsFixed(2)} ${currency.name.toUpperCase()}';
  }
}