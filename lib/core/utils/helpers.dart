int formatAmountToSave(String amount) {
  final targetAmountString = amount.replaceAll(',', '.');
  final targetAmountDouble = double.tryParse(targetAmountString) ?? 0.0;
  return (targetAmountDouble * 100).round();
}
