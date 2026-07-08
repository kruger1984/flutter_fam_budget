import 'package:family_budget/core/services/notification_service.dart';
import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:family_budget/features/category/models/category.dart';
import 'package:family_budget/features/category/providers/category_pod.dart';
import 'package:family_budget/features/transaction/models/transaction.dart';
import 'package:family_budget/features/transaction/models/transaction_type.dart';
import 'package:family_budget/features/transaction/providers/transaction_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/helpers.dart';

class CreateOrEditTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final TransactionType? initialType;

  const CreateOrEditTransactionSheet({super.key, this.transaction, this.initialType});

  @override
  ConsumerState<CreateOrEditTransactionSheet> createState() => _CreateOrEditTransactionSheetState();
}

class _CreateOrEditTransactionSheetState extends ConsumerState<CreateOrEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _targetAmountController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  Account? _selectedAccount;
  Account? _targetAccount;
  int? _selectedCategoryId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _type = tx.type;
      _descriptionController.text = tx.description ?? '';
      _amountController.text = (tx.amount / 100).toString();
      _targetAmountController.text = tx.targetAmount != null ? (tx.targetAmount! / 100).toString() : '';
      _selectedCategoryId = tx.categoryId;
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) return;

    setState(() => _isLoading = true);

    try {
      if (widget.transaction == null) {
        await ref
            .read(transactionProvider(_selectedAccount!.id).notifier)
            .createTransaction(
              type: _type,
              amount: formatAmountToSave(_amountController.text),
              currency: _selectedAccount!.currency,
              categoryId: _selectedCategoryId,
              targetAccountId: _targetAccount?.id,
              targetAmount: _targetAmountController.text.isNotEmpty ? formatAmountToSave(_targetAmountController.text) : null,
              targetCurrency: _targetAccount?.currency,
              description: _descriptionController.text.trim(),
            );
      } else {
        await ref
            .read(transactionProvider(_selectedAccount!.id).notifier)
            .updateTransaction(
              id: widget.transaction!.id,
              type: _type,
              amount: formatAmountToSave(_amountController.text),
              currency: _selectedAccount!.currency,
              categoryId: _selectedCategoryId,
              targetAccountId: _targetAccount?.id,
              targetAmount: _targetAmountController.text.isNotEmpty ? formatAmountToSave(_targetAmountController.text) : null,
              targetCurrency: _targetAccount?.currency,
              description: _descriptionController.text.trim(),
            );
      }

      if (mounted) {
        ref
            .read(notificationServiceProvider)
            .showSuccess(context: context, title: widget.transaction == null ? 'Транзакцію створено!' : 'Транзакцію оновлено!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider).showError(context: context, title: 'Помилка', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(Transaction? transaction) async {
    if (transaction == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(transactionProvider(_selectedAccount!.id).notifier).deleteTransaction(transaction);
      if (mounted) {
        ref.read(notificationServiceProvider).showSuccess(context: context, title: 'Транзакцію видалено!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider).showError(context: context, title: 'Помилка', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountProvider);
    final categoriesAsync = ref.watch(categoryProvider);

    final accounts = accountsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];

    if (_selectedAccount == null && accounts.isNotEmpty) {
      if (widget.transaction != null) {
        _selectedAccount = accounts.where((a) => a.id == widget.transaction!.accountId).firstOrNull ?? accounts.first;
      } else {
        _selectedAccount = accounts.first;
      }
    }

    if (_targetAccount == null && accounts.isNotEmpty && _type == TransactionType.transfer) {
      if (widget.transaction != null && widget.transaction!.targetAccountId != null) {
        _targetAccount = accounts.where((a) => a.id == widget.transaction!.targetAccountId).firstOrNull;
      }
    }

    final selectableCategories = <Category>[];
    for (final root in categories.where((c) => c.isRoot)) {
      if (root.children.isNotEmpty) {
        selectableCategories.addAll(root.children);
      } else {
        selectableCategories.add(root);
      }
    }

    final showTargetAmount =
        _type == TransactionType.transfer && _selectedAccount != null && _targetAccount != null && _selectedAccount!.currency != _targetAccount!.currency;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding, left: 16.0, right: 16.0, top: 24.0),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.transaction == null ? 'Нова транзакція' : 'Редагувати транзакцію',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _type == TransactionType.income
                        ? 'Дохід'
                        : _type == TransactionType.transfer
                        ? 'Переказ'
                        : 'Витрата',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _type == TransactionType.income
                          ? Colors.green
                          : _type == TransactionType.transfer
                          ? Colors.blue
                          : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))],
                        decoration: InputDecoration(
                          labelText: 'Сума',
                          suffixText: _selectedAccount?.currency.name.toUpperCase(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) => val != null && val.isEmpty ? 'Введіть суму' : null,
                      ),
                    ),
                    if (showTargetAmount) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _targetAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d{0,2}'))],
                          decoration: InputDecoration(
                            labelText: 'Сума отрим.',
                            suffixText: _targetAccount?.currency.name.toUpperCase(),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) => val != null && val.isEmpty ? 'Введіть суму' : null,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Account>(
                  initialValue: _selectedAccount,
                  decoration: const InputDecoration(labelText: 'Рахунок', border: OutlineInputBorder()),
                  items: accounts.map((account) {
                    return DropdownMenuItem(value: account, child: Text(account.name));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccount = val),
                  validator: (val) => val == null ? 'Оберіть рахунок' : null,
                ),
                if (_type == TransactionType.transfer) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Account>(
                    initialValue: _targetAccount,
                    decoration: const InputDecoration(labelText: 'На рахунок', border: OutlineInputBorder()),
                    items: accounts.where((a) => a.id != _selectedAccount?.id).map((account) {
                      return DropdownMenuItem(value: account, child: Text(account.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _targetAccount = val),
                    validator: (val) => val == null ? 'Оберіть рахунок отримувач' : null,
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    // value: _selectedCategoryId,
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Категорія', border: OutlineInputBorder()),
                    items: selectableCategories.map((category) {
                      final parentName = categories
                          .where((c) => c.id == category.parentId)
                          .firstOrNull?.name;

                      final displayName = parentName != null
                          ? '$parentName -> ${category.name}'
                          : category.name;

                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Оберіть категорію' : null,
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Опис (необов\'язково)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.transaction == null ? 'Створити' : 'Зберегти', style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 8),
                if (widget.transaction != null)
                  TextButton(
                    onPressed: () => _delete(widget.transaction),
                    child: const Text('Видалити транзакцію', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
