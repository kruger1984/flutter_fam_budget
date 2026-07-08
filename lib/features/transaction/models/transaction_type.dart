import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum TransactionType {
  @JsonValue('expense')
  expense(Colors.red, '-'),

  @JsonValue('income')
  income(Colors.green, '+'),

  @JsonValue('transfer')
  transfer(Colors.blue, '-');

  final Color color;
  final String prefix;

  const TransactionType(this.color, this.prefix);
}