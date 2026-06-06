import 'package:family_budget/core/services/notification_service.dart';
import 'package:family_budget/features/account/models/account.dart';
import 'package:family_budget/features/account/models/account_type.dart';
import 'package:family_budget/features/account/models/currency.dart';
import 'package:family_budget/features/account/providers/account_pod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateOrEditAccountSheet extends ConsumerStatefulWidget {
  final Account? account;

  const CreateOrEditAccountSheet({super.key, this.account});

  @override
  ConsumerState<CreateOrEditAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends ConsumerState<CreateOrEditAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');

  AccountType _selectedType = AccountType.cash;
  Currency _selectedCurrency = Currency.uah;

  bool _isPersonal = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedCurrency = widget.account!.currency;
      _isPersonal = widget.account!.isPersonal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(accountProvider.notifier)
          .createAccount(
            name: _nameController.text.trim(),
            type: _selectedType,
            currency: _selectedCurrency,
            balance: int.parse(_balanceController.text),
            isPersonal: _isPersonal,
          );

      if (mounted) {
        ref.read(notificationServiceProvider).showSuccess(context: context, title: 'Рахунок успішно створено!');

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider).showError(context: context, title: 'Помилка створення', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding, left: 16.0, right: 16.0, top: 24.0),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Новий рахунок',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Назва рахунку (напр. Зарплатна картка)', border: OutlineInputBorder()),
                validator: (val) => val != null && val.isEmpty ? 'Введіть назву' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Початковий баланс', border: OutlineInputBorder()),
                validator: (val) => val != null && val.isEmpty ? 'Введіть баланс' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AccountType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(labelText: 'Тип', border: OutlineInputBorder()),
                      items: AccountType.values.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Currency>(
                      initialValue: _selectedCurrency,
                      decoration: const InputDecoration(labelText: 'Валюта', border: OutlineInputBorder()),
                      items: Currency.values.map((currency) {
                        return DropdownMenuItem(value: currency, child: Text(currency.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCurrency = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Особистий рахунок'),
                subtitle: const Text('Вимкніть, щоб зробити його спільним для сім\'ї'),
                value: _isPersonal,
                onChanged: (val) => setState(() => _isPersonal = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Створити', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
